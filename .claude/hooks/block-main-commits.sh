#!/usr/bin/env bash
#
# block-main-commits.sh
#
# Purpose
#   Refuse Bash commands that would create a new commit on the protected
#   branches `main` or `master`.
#
# When it runs
#   PreToolUse, on the Bash tool. Claude Code passes the tool invocation
#   as JSON on stdin.
#
# What it blocks
#   git commit          git revert
#   git commit --amend  git merge
#   git cherry-pick     git rebase
#
#   Blocks regardless of --no-commit. Over-blocking on a protected branch
#   is the safer default; if you need to run one of these on main without
#   creating a commit, do it manually.
#
#   `git push` is deliberately absent; guard-force-push.sh owns pushes.
#   Adding `push` here would only re-block legitimate feature-branch pushes.
#
# Behavior
#   exit 0  → allow the Bash command to run
#   exit 2  → block (Claude Code surfaces stderr to the agent)
#
# Failure mode
#   Fail closed. Any unexpected error (JSON parse failure, empty stdin,
#   failure to resolve the current branch, shell error) exits 2 with a
#   diagnostic. A malformed hook payload or an unresolvable HEAD can never
#   silently allow a commit on a protected branch. A detached HEAD resolves
#   to the literal `HEAD`, which is not protected, and is allowed. An unborn
#   branch (a fresh repo before its first commit) cannot be resolved and is
#   blocked — make that first commit manually.
#
# Testing
#   On a checkout of main:
#     echo '{"tool_input":{"command":"git commit -m x"}}' | ./block-main-commits.sh
#   Expected: exit 2 and the protected-branch message on stderr.
#
#   From a directory that is not a git repository:
#     cd /tmp && echo '{"tool_input":{"command":"git commit -m x"}}' | \
#       /path/to/block-main-commits.sh
#   Expected: exit 2 and "could not determine current branch" on stderr.

set -uo pipefail

fail_closed() {
  echo "block-main-commits.sh: $1 — defaulting to BLOCK." >&2
  exit 2
}
trap 'fail_closed "unexpected error at line $LINENO"' ERR

input="$(cat 2>/dev/null)" || fail_closed "could not read stdin"
[[ -n "$input" ]] || fail_closed "empty stdin"

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')" \
  || fail_closed "jq failed to parse hook input"

if ! [[ "$cmd" =~ ^[[:space:]]*git[[:space:]]+(commit|cherry-pick|revert|merge|rebase)([[:space:]]|$) ]]; then
  exit 0
fi

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" \
  || fail_closed "could not determine current branch"
if [[ "$branch" == "main" || "$branch" == "master" ]]; then
  cat >&2 <<EOF
Refusing to run on protected branch '$branch':
  $cmd

Create a feature branch first:  git checkout -b <branch-name>

Then re-run the command.
EOF
  exit 2
fi

exit 0
