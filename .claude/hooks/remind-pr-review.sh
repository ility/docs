#!/usr/bin/env bash
#
# remind-pr-review.sh
#
# Purpose
#   The moment an agent opens a PR, tell it to start the PR's independent
#   review without asking. standards/git.md makes that review the agent's
#   job before it flips the draft ready, but agents kept stopping to offer it
#   ("want me to run it?"). Injecting the rule at creation time removes the ask.
#
# When it runs
#   PostToolUse, on Bash and on any GitHub MCP server's create_pull_request
#   tool. Registered for both Claude Code and Codex.
#
# What it acts on
#   Emits hookSpecificOutput.additionalContext, which both agents add to the
#   model's context, only when a PR was actually created:
#     - a `gh [-R repo] pr create` (or its alias `pr new`) command whose
#       output has a bare PR URL on its own line;
#     - a `gh api repos/<o>/<r>/pulls` command with POST fields and no
#       `-X GET`, whose output carries the new PR's html_url (or, with
#       --jq, a bare PR URL);
#     - an MCP `*__create_pull_request` call whose response names a PR.
#   Bash commands are split into their shell segments first — heredoc
#   bodies dropped, quoted strings flattened into the segment they sit in —
#   and each segment is tested on its own, from its start (after any
#   `VAR=x`, `env`, `!`, `if`, `timeout N` prefixes). So `gh pr create`
#   quoted in a --body, and a `-f` or `-X GET` belonging to another command
#   in the pipeline, don't count. gh's "a pull request … already exists"
#   refusal, which prints the old PR's URL, never fires. `bash -c "…"`
#   wrappers are not recognized — the AGENTS.md rule is the primary; this is
#   the backstop.
#
# Behavior
#   exit 0 always. The hook is advisory — git.md's ready conditions are the
#   rule; this only puts them in front of the agent at the right moment.
#   The reminder is hookSpecificOutput.additionalContext JSON on stdout —
#   stderr from an exit-0 hook never reaches the agent (ility/ility docs/standards/shell.md).
#   Matching uses [[ =~ ]] rather than `printf | grep -q`, which returns 141
#   under pipefail when grep exits before a large command is written.
#
# Failure mode
#   Fails open. If jq is missing or the input doesn't parse, it stays silent.
#
# Testing
#   From the repo root:
#     echo '{"tool_name":"Bash","tool_input":{"command":"gh pr create --draft"},"tool_response":{"stdout":"https://github.com/o/r/pull/1\n"}}' \
#       | .claude/hooks/remind-pr-review.sh
#   Expected: exit 0 with a JSON additionalContext object on stdout.
#   With "command":"gh pr comment 1 --body 'gh pr create'" it prints nothing.

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)" || exit 0
# Every string in the response, newline-joined, whatever shape the agent
# gives it (Claude Code: {stdout, stderr} or MCP content blocks; Codex: any).
response="$(printf '%s' "$input" \
  | jq -r '[.tool_response // "" | .. | strings] | join("\n")' 2>/dev/null)" || exit 0

nl=$'\n'
# gh's refusal when the branch already has a PR, and the GitHub API's.
refused="[Pp]ull request (for branch [^${nl}]* )?already exists"
[[ ! "$response" =~ $refused ]] || exit 0

pr_url_line="(^|${nl})https://github\\.com/[^/[:space:]]+/[^/[:space:]]+/pull/[0-9]+[[:space:]]*(${nl}|$)"
pr_html_url="\"html_url\":[[:space:]]*\"https://github\\.com/[^\"/]+/[^\"/]+/pull/[0-9]+\""
pr_url="github\\.com/[^/\"[:space:]]+/[^/\"[:space:]]+/pull/[0-9]+"

# The command's shell segments: heredoc bodies dropped, quoted strings
# flattened (their separators blanked, so quoted text stays inside the
# segment it belongs to) and `#` comments removed in the same left-to-right
# pass — so a `#` inside quotes is text and a `'` inside a comment is not a
# quote, as in the shell — then split on ; & | ( ) && || and newlines.
read -r -d '' segments_jq <<'JQ' || true
.tool_input.command // ""
| gsub("<<-?[ \t]*(?<q>['\"]?)(?<t>[A-Za-z_][A-Za-z0-9_]*)\\k<q>(?<rest>[^\n]*)\n(?:[\\s\\S]*?\n)??[ \t]*\\k<t>(?=\n|\\z)"; .rest)
| gsub("'(?<s>[^']*)'|\"(?<d>(?:\\\\.|[^\"\\\\])*)\"|(?<c>(?:^|(?<=[\\s;&|()]))#[^\n]*)"; if .c then "" else ((.s // .d) | gsub("[;&|()\n]"; " ")) end)
| [splits("&&|\\|\\||[;&|\n()]") | gsub("^\\s+|\\s+$"; "") | select(length > 0)]
| .[]
JQ

created=false
if [[ "$tool_name" == "Bash" ]]; then
  segments="$(printf '%s' "$input" | jq -r "$segments_jq" 2>/dev/null)" || exit 0
  prefix="(([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*|env|command|exec|nohup|time|!|if|then|else|elif|do|while|until|timeout[[:space:]]+[^[:space:]]+)[[:space:]]+)*"
  gh="^${prefix}([^[:space:]]*/)?gh([[:space:]]+(-R|--repo)([[:space:]]+|=)[^[:space:]]+)*[[:space:]]+"
  create_re="${gh}pr[[:space:]]+(create|new)([[:space:]]|$)"
  api_re="${gh}api([[:space:]]|$)"
  pulls_re="(^|[[:space:]]|=)/?repos/[^/[:space:]]+/[^/[:space:]]+/pulls([[:space:]]|$)"
  post_re="[[:space:]](-X[[:space:]]*|--method([[:space:]]+|=))[Pp][Oo][Ss][Tt]([[:space:]]|$)|[[:space:]](-f|-F|--field|--raw-field|--input)([[:space:]]|=)"
  get_re="[[:space:]](-X[[:space:]]*|--method([[:space:]]+|=))[Gg][Ee][Tt]([[:space:]]|$)"
  while IFS= read -r seg; do
    if [[ "$seg" =~ $create_re && "$response" =~ $pr_url_line ]]; then
      created=true
    elif [[ "$seg" =~ $api_re && "$seg" =~ $pulls_re && "$seg" =~ $post_re \
      && ! "$seg" =~ $get_re ]] \
      && [[ "$response" =~ $pr_html_url || "$response" =~ $pr_url_line ]]; then
      created=true
    fi
  done <<<"$segments"
elif [[ "$tool_name" =~ ^mcp__.+__create_pull_request$ && "$response" =~ $pr_url ]]; then
  created=true
fi
[[ "$created" == true ]] || exit 0

read -r -d '' message <<'EOF' || true
You just opened a pull request. Start its independent review now, without asking the user whether to (standards/git.md#pull-requests — that rule is standing authorization to run and post it):
1. Dispatch a reviewer that does not carry your session: a fresh subagent in its own worktree, given the PR, its base..head range, and the standards it touches (standards/code-review.md#dispatching-the-reviewer). Post its findings to the PR as a review.
2. Fix or disposition every finding in a follow-up PR comment, per standards/code-review.md#the-disposition-framework.
3. Flip the PR ready only when all four of git.md's conditions hold — including every check on the head SHA green with a non-zero check-run count (a fresh push has none yet) and a clean merge — then tell the user it is ready to merge.
EOF

jq -n --arg ctx "$message" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'

exit 0
