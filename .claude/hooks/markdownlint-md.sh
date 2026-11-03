#!/usr/bin/env bash
#
# markdownlint-md.sh
#
# Purpose
#   After an edit to a Markdown file, run markdownlint-cli2 and surface any
#   violations in the just-edited file. Gives the agent immediate feedback
#   instead of letting the Markdown workflow catch it after a push. Copied
#   from ility/ility, where MD034 (bare URLs) reddened CI more than once.
#
# When it runs
#   PostToolUse, on Edit and Write tools targeting *.md and *.mdx files.
#
# What it acts on
#   Runs markdownlint-cli2 from the repo root and filters output to lines
#   naming the edited file, reporting the first 30. The repo config sets its own globs and ignores,
#   so a single-file argument would be merged with them rather than
#   narrowing the run — filtering the output is what scopes this to the
#   edited file. Files under the config's `ignores` (notably
#   `.claude/commands`) produce no output here, matching CI.
#
# Behavior
#   exit 0 always. The hook is advisory — it does not block edits. The
#   Markdown workflow is the hard gate. When violations are found in the
#   edited file, they are printed to stdout as
#   hookSpecificOutput.additionalContext JSON, which puts them in the
#   agent's context. Stderr would not: an exit-0 hook's stderr never
#   reaches the agent.
#
# Failure mode
#   This repo has no package.json, so the CLI comes from a markdownlint-cli2
#   on PATH, else from `npx --yes markdownlint-cli2@0.17.2` (the version
#   ility/ility pins; npm caches it after the first run). Fails open if
#   none of those works: skipping the scan beats blocking the agent.
#
# Testing
#   From the repo root, add a bare URL to index.mdx, then run:
#     echo '{"tool_input":{"file_path":"index.mdx"}}' | .claude/hooks/markdownlint-md.sh
#   Expected: exit 0 with a JSON additionalContext object on stdout
#   naming the MD034 violation. Revert the edit afterwards.

set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')"

case "$file_path" in
  *.md|*.mdx) ;;
  *) exit 0 ;;
esac

repo_root="${CLAUDE_PROJECT_DIR:-}"
if [[ -z "$repo_root" ]]; then
  repo_root="$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[[ -n "$repo_root" && -d "$repo_root" ]] || exit 0

# Locate node — PATH may not include nvm in this context.
NODE_BIN="$(command -v node 2>/dev/null || true)"
if [[ -z "$NODE_BIN" ]]; then
  for c in /opt/homebrew/bin/node /usr/local/bin/node "$HOME"/.nvm/versions/node/*/bin/node; do
    if [[ -x "$c" ]]; then NODE_BIN="$c"; break; fi
  done
fi
[[ -n "$NODE_BIN" ]] || exit 0

CLI="$repo_root/node_modules/markdownlint-cli2/markdownlint-cli2-bin.mjs"
run_lint=("$NODE_BIN" "$CLI")
if [[ ! -f "$CLI" ]]; then
  global_cli="$(command -v markdownlint-cli2 2>/dev/null || true)"
  npx_bin="$(dirname "$NODE_BIN")/npx"
  if [[ -n "$global_cli" ]]; then
    run_lint=("$global_cli")
  elif [[ -x "$npx_bin" ]]; then
    run_lint=("$npx_bin" --yes markdownlint-cli2@0.17.2)
  else
    exit 0
  fi
fi

# Violations are reported relative to the run directory, so match on the
# edited file's path relative to the repo root.
relative="${file_path#"$repo_root"/}"

output="$(cd "$repo_root" && "${run_lint[@]}" 2>&1 || true)"
matching="$(grep -F "$relative:" <<<"$output" || true)"

if [[ -n "$matching" ]]; then
  total="$(wc -l <<<"$matching" | tr -d ' ')"
  header="Markdown violations in $relative:"
  (( total > 30 )) && header="Markdown violations in $relative (first 30 of $total):"
  message="$(printf '%s\n%s\n\nRule reference: https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md' "$header" "$(sed -n '1,30p' <<<"$matching")")"
  jq -n --arg ctx "$message" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
fi

exit 0
