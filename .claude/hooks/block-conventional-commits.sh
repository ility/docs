#!/usr/bin/env bash
#
# block-conventional-commits.sh
#
# Purpose
#   Refuse git commit commands whose message starts with a conventional-commit
#   prefix (feat:, fix:, chore:, refactor:, docs:, style:, test:, build:,
#   ci:, perf:, revert:). This project uses imperative mood without prefixes.
#
# When it runs
#   PreToolUse, on the Bash tool.
#
# What it blocks
#   Any git commit -m "..." where the message (or the first line of a
#   HEREDOC body embedded in the command) matches the conventional-commit
#   pattern. Scans the full command string, so it catches both:
#     git commit -m "feat: add endpoint"
#     git commit -m "$(cat <<'EOF'\nfeat: add endpoint\n...EOF\n)"
#
# Limitation
#   Scanning the raw command string means the pattern could theoretically
#   match a conventional-commit phrase in the message *body* (not subject).
#   In practice this is rare; the safer backstop is a git commit-msg hook.
#
# Behavior
#   exit 0  → allow
#   exit 2  → block (Claude Code surfaces stderr to the agent)
#
# Failure mode
#   Fail closed. Any unexpected error exits 2 with a diagnostic.

set -uo pipefail

fail_closed() {
  echo "block-conventional-commits.sh: $1 — defaulting to BLOCK." >&2
  exit 2
}
trap 'fail_closed "unexpected error at line $LINENO"' ERR

input="$(cat 2>/dev/null)" || fail_closed "could not read stdin"
[[ -n "$input" ]] || fail_closed "empty stdin"

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')" \
  || fail_closed "jq failed to parse hook input"

# Only inspect git commit commands.
if ! [[ "$cmd" =~ ^[[:space:]]*git[[:space:]]+commit([[:space:]]|$) ]]; then
  exit 0
fi

# Block if the conventional-commit pattern appears anywhere in the command.
if printf '%s' "$cmd" | grep -Eq \
  '^(feat|fix|chore|refactor|docs|style|test|build|ci|perf|revert)(\(.+\))?!?:[[:space:]]|[^a-z](feat|fix|chore|refactor|docs|style|test|build|ci|perf|revert)(\(.+\))?!?:[[:space:]]'; then
  cat >&2 <<'EOF'
Refusing conventional-commit prefix in commit message.

This project uses imperative mood without prefixes. See standards/git.md.

  Wrong:  feat: add scan endpoint
  Right:  Add scan endpoint

  Wrong:  fix(auth): handle expired tokens
  Right:  Handle expired token expiry in auth middleware
EOF
  exit 2
fi

exit 0
