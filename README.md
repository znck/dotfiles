# dotfiles

**My dotfiles**

## Personal agent commit author

Run this inside a Git repo clone to switch that repo/worktree between the
default user author and the personal GitHub App bot author:

```bash
git acts
git acts agent
git acts user
git acts status
```

The shell prompt shows the effective Git commit author when it differs from the
global default. The installed checkout hook switches only linked worktrees to
the agent author; the primary clone stays on the author you selected.

To run standard GitHub CLI commands as the GitHub App, set
`ZNCK_AGENT_PRIVATE_KEY_PATH` (or `ZNCK_AGENT_PRIVATE_KEY`). Interactive zsh
shells use normal user auth. Non-interactive shells use a short-lived App
installation token when the current repo has an installation.
Non-interactive zsh sets `ZNCK_AGENT_MODE=1`, so `gh` and Git credentials prefer
the agent token without changing the repo's commit author. Set
`ZNCK_AGENT_MODE=0` for normal user auth in a specific non-interactive command.

```bash
gh pr create --fill
```

Agent-mode repos set an HTTPS push URL for the current worktree, so pushes can
use token credentials instead of an SSH key. `agent-git-credential` returns a
short-lived App token only when the current repo/worktree is in agent mode;
otherwise Git falls through to normal user credentials.
