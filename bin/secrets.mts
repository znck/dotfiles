#!/usr/bin/env node

import { execFile as execFileCallback, type ExecFileException } from "node:child_process";
import { access, mkdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import { constants } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { env, argv, cwd, exit, stdin, stdout } from "node:process";
import { Buffer } from "node:buffer";
import { promisify } from "node:util";

const execFile = promisify(execFileCallback);
const encodedSecretPrefix = "znck-secrets:v1:";

type Options = {
  key?: string;
  help?: boolean;
};

type ParsedArgs = {
  command?: string;
  values: string[];
  options: Options;
};

function help() {
  console.log(`secrets <command>

Commands:
  save [filename]    save a secret file in keychain
  load [filename]    load keychain item
  read [filename]    read keychain item to stdout
  ls                 list keychain items
  rm --key <key>     remove keychain item
  save-all           save all listed secret files in keychain
  load-all           load all listed keychain items to local files

Options:
  -k, --key <key>    name of keychain item
  -h, --help         show help`);
}

function parseArgs(args: string[]): ParsedArgs {
  const values: string[] = [];
  const options: Options = {};
  let command: string | undefined;

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];

    if (arg === "-h" || arg === "--help") {
      options.help = true;
    } else if (arg === "-k" || arg === "--key") {
      const value = args[index + 1];
      if (value == null) throw new Error(`${arg} requires a value`);
      options.key = value;
      index += 1;
    } else if (arg.startsWith("--key=")) {
      options.key = arg.slice("--key=".length);
    } else if (arg.startsWith("-")) {
      throw new Error(`Unknown option: ${arg}`);
    } else if (command == null) {
      command = arg;
    } else {
      values.push(arg);
    }
  }

  return { command, values, options };
}

function home() {
  return env.HOME ?? "/";
}

function expandHome(filename: string) {
  return filename.replace(/^~(?=$|\/)/, home());
}

function resolveFilename(filename: string) {
  return resolve(cwd(), expandHome(filename));
}

function keyForFilename(filename: string) {
  return `~/${relative(home(), resolveFilename(filename))}`;
}

async function canReadFile(filename: string) {
  await access(filename, constants.R_OK);
}

async function canWriteFile(filename: string) {
  await mkdir(dirname(filename), { recursive: true });

  try {
    await access(filename, constants.W_OK);
  } catch (error) {
    const code = typeof error === "object" && error != null && "code" in error ? error.code : undefined;
    if (code !== "ENOENT") throw error;
  }
}

async function readStdin() {
  const chunks: Buffer[] = [];

  for await (const chunk of stdin) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }

  return Buffer.concat(chunks).toString("utf8");
}

function securityArgs(args: string[], keychain: string) {
  return [...args, keychain];
}

async function security(args: string[]) {
  const { stdout } = await execFile("/usr/bin/security", args, {
    encoding: "utf8",
    maxBuffer: 1024 * 1024 * 20,
  });

  return stdout;
}

function stripSecurityLineEnding(contents: string) {
  if (contents.endsWith("\r\n")) return contents.slice(0, -2);
  if (contents.endsWith("\n")) return contents.slice(0, -1);
  return contents;
}

function encodeSecret(contents: string) {
  return `${encodedSecretPrefix}${Buffer.from(contents, "utf8").toString("base64")}`;
}

function decodeSecret(contents: string) {
  const encoded = stripSecurityLineEnding(contents);
  if (!encoded.startsWith(encodedSecretPrefix)) return encoded;
  return Buffer.from(encoded.slice(encodedSecretPrefix.length), "base64").toString("utf8");
}

async function syncKeychain(keychain: string) {
  try {
    await execFile("/usr/bin/fileproviderctl", ["evaluate", keychain]);
  } catch (error) {
    const stderr =
      typeof error === "object" && error != null && "stderr" in error ? String((error as ExecFileException).stderr) : "";
    if (stderr.includes("No item for URL") || stderr.includes("NSFileProviderErrorDomain Code=-1005")) return;
    throw error;
  }
}

function keychainPath() {
  return env.SECRETS_PATH ?? join(home(), "Documents/Secrets.keychain-db");
}

async function listSecrets(keychain: string) {
  const dump = await security(["dump-keychain", keychain]);
  const services = new Set<string>();
  const pattern = /"svce"<blob>="([^"]*)"/g;

  for (const match of dump.matchAll(pattern)) {
    services.add(match[1]);
  }

  return [...services].sort();
}

async function deleteSecret(keychain: string, key: string, ignoreMissing = false) {
  try {
    await security(securityArgs(["delete-generic-password", "-a", "", "-s", key, "-C", "note"], keychain));
  } catch (error) {
    if (ignoreMissing) return;
    throw error;
  }
}

async function findSecret(keychain: string, key: string) {
  return decodeSecret(await security(securityArgs(["find-generic-password", "-a", "", "-s", key, "-w", "-C", "note"], keychain)));
}

async function addSecret(keychain: string, key: string, contents: string) {
  await security(
    securityArgs(
      [
        "add-generic-password",
        "-a",
        "",
        "-s",
        key,
        "-w",
        encodeSecret(contents),
        "-C",
        "note",
        "-T",
        "",
        "-D",
        "secure note",
      ],
      keychain,
    ),
  );
}

async function saveSecret(keychain: string, filename: string | undefined, key?: string) {
  let contents: string;

  if (filename == null || filename === "-") {
    if (key == null) throw new Error("--key is required when reading from stdin");
    contents = await readStdin();
  } else {
    const infile = resolveFilename(filename);
    await canReadFile(infile);
    contents = await readFile(infile, "utf8");
    key = key ?? keyForFilename(filename);
  }

  await deleteSecret(keychain, key, true);
  await addSecret(keychain, key, contents);
}

async function loadSecret(keychain: string, filename: string | undefined, key?: string) {
  if (filename == null || filename === "-") {
    if (key == null) throw new Error("--key is required when writing to stdout");
  } else {
    key = key ?? keyForFilename(filename);
  }

  const contents = await findSecret(keychain, key);

  if (filename == null || filename === "-") {
    stdout.write(contents);
    return;
  }

  const outfile = resolveFilename(filename);
  await canWriteFile(outfile);

  let mode = 0o400;

  try {
    mode = (await stat(outfile)).mode;
  } catch {
    // Keep the default mode for new files.
  }

  await rm(outfile, { force: true });
  await writeFile(outfile, contents, { mode });
}

async function readSecret(keychain: string, filename: string | undefined, key?: string) {
  if (filename == null || filename === "-") {
    if (key == null) throw new Error("--key is required when writing to stdout");
  } else {
    key = key ?? keyForFilename(filename);
  }

  const contents = await findSecret(keychain, key);
  stdout.write(contents);
}

async function main() {
  const parsed = parseArgs(argv.slice(2));

  if (parsed.options.help || parsed.command == null) {
    help();
    return;
  }

  const keychain = keychainPath();
  await syncKeychain(keychain);

  switch (parsed.command) {
    case "save":
      await saveSecret(keychain, parsed.values[0], parsed.options.key);
      break;

    case "load":
      await loadSecret(keychain, parsed.values[0], parsed.options.key);
      break;

    case "read":
      await readSecret(keychain, parsed.values[0], parsed.options.key);
      break;

    case "ls": {
      const items = await listSecrets(keychain);
      console.log(items.join("\n"));
      break;
    }

    case "rm":
      if (parsed.options.key == null) throw new Error("--key is required");
      await deleteSecret(keychain, parsed.options.key);
      break;

    case "save-all": {
      const items = await listSecrets(keychain);

      for (const item of items) {
        const filename = item.replace("~", home());
        console.log(`Saving "${item}" from "${filename}"`);
        await saveSecret(keychain, filename, item);
      }

      if (items.length === 0) console.warn("No secrets");
      break;
    }

    case "load-all": {
      const items = await listSecrets(keychain);

      for (const item of items) {
        const filename = item.replace("~", home());
        console.log(`Loading "${item}" to "${filename}"`);
        await loadSecret(keychain, filename, item);
      }

      if (items.length === 0) console.warn("No secrets");
      break;
    }

    default:
      throw new Error(`Unknown command: ${parsed.command}`);
  }
}

try {
  await main();
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  exit(1);
}
