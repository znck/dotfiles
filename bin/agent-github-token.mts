#!/usr/bin/env node

import * as process from "node:process";
import { createSign } from "node:crypto";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";

const appId = process.env.ZNCK_AGENT_APP_ID || "4119275";
const apiUrl = process.env.GITHUB_API_URL || "https://api.github.com";
const remote = process.argv[2] || "origin";

function fail(message: string): never {
  console.error(`agent-github-token: ${message}`);
  process.exit(1);
}

function git(args: string[]) {
  return execFileSync("git", args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
}

function privateKey() {
  if (process.env.ZNCK_AGENT_PRIVATE_KEY) return process.env.ZNCK_AGENT_PRIVATE_KEY;

  const keyPath = process.env.ZNCK_AGENT_PRIVATE_KEY_PATH;
  if (!keyPath) {
    fail("set ZNCK_AGENT_PRIVATE_KEY_PATH or ZNCK_AGENT_PRIVATE_KEY");
  }

  return readFileSync(keyPath.replace(/^~(?=$|\/)/, homedir()), "utf8");
}

function parseGitHubRemote(url: string) {
  const patterns = [
    /^git@github\.com:([^/]+)\/(.+?)(?:\.git)?$/,
    /^ssh:\/\/git@github\.com\/([^/]+)\/(.+?)(?:\.git)?$/,
    /^https:\/\/github\.com\/([^/]+)\/(.+?)(?:\.git)?$/,
  ];

  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) return { owner: match[1], repo: match[2] };
  }

  fail(`cannot parse GitHub remote URL: ${url}`);
}

function base64url(value: string) {
  return Buffer.from(value).toString("base64url");
}

function jwt() {
  const issuedAt = Math.floor(Date.now() / 1000) - 60;
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64url(JSON.stringify({ iat: issuedAt, exp: issuedAt + 9 * 60, iss: appId }));
  const data = `${header}.${payload}`;
  const signer = createSign("RSA-SHA256");
  signer.update(data);
  signer.end();
  return `${data}.${signer.sign(privateKey(), "base64url")}`;
}

async function github(path: string, options: RequestInit = {}) {
  const response = await fetch(`${apiUrl}${path}`, {
    ...options,
    headers: {
      Accept: "application/vnd.github+json",
      Authorization: `Bearer ${jwt()}`,
      "X-GitHub-Api-Version": "2022-11-28",
      ...(options.headers || {}),
    },
  });
  const text = await response.text();
  const body = text ? JSON.parse(text) : {};
  if (!response.ok) {
    fail(`${options.method || "GET"} ${path} failed: ${response.status} ${body.message || text}`);
  }
  return body;
}

const remoteUrl = git(["remote", "get-url", remote]);
const { owner, repo } = parseGitHubRemote(remoteUrl);
const installation = await github(`/repos/${owner}/${repo}/installation`);
const token = await github(`/app/installations/${installation.id}/access_tokens`, {
  method: "POST",
});

if (!token.token) fail("GitHub did not return an installation token");
process.stdout.write(token.token);
