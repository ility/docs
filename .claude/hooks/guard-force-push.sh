#!/usr/bin/env bash
#
# guard-force-push.sh
#
# Purpose
#   Constrain force-pushes to what is actually safe, at the layer that can
#   see the target branch. Permission rules in settings.json match command
#   strings with prefix wildcards, so they can only allow or deny a flag
#   everywhere; they cannot express "any branch except main". A hook can.
#
# What it refuses
#   1. Any push whose target ref is a protected branch (main, master),
#      force or not. Overlaps the deny rules in settings.json and any
#      server-side branch ruleset — kept because a local refusal is faster
#      to read than a server rejection, and holds even where the remote has
#      no ruleset.
#
#   2. A force-push that is not pinned to an expected SHA:
#        --force                          → refused
#        -f                               → refused
#        +<ref> refspec                   → refused
#        --force-with-lease               → refused (bare)
#        --force-with-lease=<ref>         → refused (no expected SHA)
#        --force-with-lease=<ref>:<sha>   → ALLOWED
#
#      The bare and ref-only forms compare against the remote-tracking ref,
#      which `git fetch` updates. So `git fetch && git push
#      --force-with-lease` satisfies the lease even when a colleague pushed
#      before that fetch — the lease protects nothing in the one sequence
#      an automated agent is most likely to run. Pinning to a SHA the
#      pusher actually read closes that.
#
# When it runs
#   PreToolUse, on the Bash tool. Claude Code passes the tool invocation as
#   JSON on stdin.
#
# Behavior
#   exit 0  → allow
#   exit 2  → block (Claude Code surfaces stderr to the agent)
#
# Failure mode
#   Fail closed, including branch detection. Every path that cannot
#   establish what a command targets exits 2. Note this is the property
#   block-main-commits.sh documents but does not hold on its branch-check
#   path, where `|| true` swallows a rev-parse failure and allows the
#   command (see ility/ility#880) — do not copy that pattern here.
#
# Testing
#   echo '{"tool_input":{"command":"git push --force-with-lease origin HEAD:topic"}}' | ./guard-force-push.sh   # 2
#   echo '{"tool_input":{"command":"git push --force-with-lease=topic:abc123 origin HEAD:topic"}}' | ./guard-force-push.sh  # 0
#   echo '{"tool_input":{"command":"git push origin HEAD:main"}}' | ./guard-force-push.sh   # 2
#   echo '{"tool_input":{"command":"git push origin topic"}}' | ./guard-force-push.sh       # 0

set -uo pipefail

PROTECTED_RE='^(main|master)$'

fail_closed() {
  echo "guard-force-push.sh: $1 — defaulting to BLOCK." >&2
  exit 2
}
trap 'fail_closed "unexpected error at line $LINENO"' ERR

input="$(cat 2>/dev/null)" || fail_closed "could not read stdin"
[[ -n "$input" ]] || fail_closed "empty stdin"

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')" \
  || fail_closed "jq failed to parse hook input"

# Only git push concerns us. Anything else, including `git push` appearing
# inside a longer pipeline argument, is left to the other hooks.
[[ "$cmd" =~ (^|[[:space:]|&;])git[[:space:]]+push([[:space:]]|$) ]] || exit 0

# --- Is this a force push, and if so is it pinned? ---------------------------

forced=0
pinned=0

if [[ "$cmd" =~ (^|[[:space:]])--force-with-lease=([^[:space:]]+) ]]; then
  forced=1
  lease="${BASH_REMATCH[2]}"
  # Pinned form is <ref>:<expected>. A bare <ref> falls back to the
  # remote-tracking ref, which is the form a preceding fetch defeats.
  if [[ "$lease" == *:* && -n "${lease#*:}" ]]; then
    pinned=1
  fi
elif [[ "$cmd" =~ (^|[[:space:]])--force-with-lease([[:space:]]|$) ]]; then
  forced=1
elif [[ "$cmd" =~ (^|[[:space:]])(--force|-f)([[:space:]]|$) ]]; then
  forced=1
elif [[ "$cmd" =~ (^|[[:space:]])\+[^[:space:]]+:  || "$cmd" =~ [[:space:]]\+[A-Za-z0-9._/-]+([[:space:]]|$) ]]; then
  # A leading + on a refspec is a force push in refspec syntax.
  forced=1
fi

# --- What does it target? ----------------------------------------------------

targets=()

# Explicit refspecs: <src>:<dst>, possibly force-prefixed. The destination
# is what lands on the remote.
while read -r spec; do
  [[ -n "$spec" ]] && targets+=("${spec##*:}")
done < <(printf '%s\n' "$cmd" | grep -oE '(^|[[:space:]])\+?[A-Za-z0-9._/@{}^~-]+:[A-Za-z0-9._/-]+' | sed 's/^[[:space:]]*//')

# `git push [--flags] <remote> <branch>` with no colon: the bare branch is
# both source and destination.
if [[ ${#targets[@]} -eq 0 ]]; then
  # Strip flags and the leading `git push`, then take positional args.
  # First positional is the remote, second (if any) the refspec.
  # Read into an array without mapfile, which is bash 4+ and absent on the
  # bash 3.2 that macOS ships.
  pos=()
  while IFS= read -r word; do
    [[ -n "$word" ]] && pos+=("$word")
  done < <(printf '%s\n' "$cmd" \
    | sed -E 's/.*git[[:space:]]+push[[:space:]]*//' \
    | tr ' ' '\n' \
    | grep -vE '^-' || true)
  if [[ ${#pos[@]} -ge 2 && -n "${pos[1]}" ]]; then
    targets+=("${pos[1]#+}")
  fi
fi

# No explicit target: git pushes the current branch. This must fail closed —
# if we cannot tell what branch we are on, we cannot tell whether it is
# protected.
if [[ ${#targets[@]} -eq 0 ]]; then
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" \
    || fail_closed "could not resolve HEAD to decide the push target"
  [[ -n "$branch" ]] || fail_closed "git rev-parse returned an empty branch"
  [[ "$branch" != "HEAD" ]] || fail_closed "detached HEAD: cannot determine the push target"
  targets+=("$branch")
fi

# --- Decide ------------------------------------------------------------------

for t in "${targets[@]}"; do
  # Strip refs/heads/ so refs/heads/main is caught alongside main.
  short="${t#refs/heads/}"
  if [[ "$short" =~ $PROTECTED_RE ]]; then
    cat >&2 <<EOF
Refusing to push to protected branch '$short':
  $cmd

'$short' only changes through a pull request (standards/git.md). Open a pull
request instead.
EOF
    exit 2
  fi
done

if [[ $forced -eq 1 && $pinned -eq 0 ]]; then
  cat >&2 <<EOF
Refusing an unpinned force-push:
  $cmd

Use the pinned lease form, naming the SHA you actually read:

  git push --force-with-lease=<branch>:<sha-you-read> origin HEAD:<branch>

--force and -f overwrite whatever is there. A bare --force-with-lease (or
--force-with-lease=<branch> with no SHA) compares against the remote-tracking
ref, which 'git fetch' updates — so 'git fetch && git push --force-with-lease'
passes the check even when someone else pushed before that fetch. Pinning to a
SHA you read makes the check mean what it appears to mean.

Read the current value with:
  git ls-remote origin <branch>
EOF
  exit 2
fi

exit 0
