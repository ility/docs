# Git conventions

How commits, branches, and pull requests work in `ility/docs`. Every
contributor follows these rules, human or agent. They match
[`ility/ility`'s `docs/standards/git.md`](https://github.com/ility/ility/blob/main/docs/standards/git.md),
which is the source of truth for every Ility repo. This copy keeps the rules
that apply here and notes where this repo differs.

## Commits

- **Imperative mood** in the subject line: "Add", "Fix", "Remove", not
  "Added" or "Adds".
- **No conventional-commit prefixes.** No `feat:`, `fix:`, `chore:`,
  `docs:`, and so on. `.claude/hooks/block-conventional-commits.sh` refuses
  them.
- **No topic prefixes either.** Write "Explain how to rotate an API key",
  not "API: key rotation". The subject is a sentence that starts with a verb.
- Mintlify's own editor and agent commit as `docs: …`. Those commits don't
  pass through these hooks; when you write the commit, follow this page.
- **Atomic.** One logical change per commit. If the subject needs an "and",
  consider splitting it.
- **Short subject.** Aim for about 70 characters or fewer.
- **The body is for the why**, not the what. Use it when the reason isn't
  obvious from the diff.
- **No references to plan structure.** Don't write "Phase 1: Add …" or
  "Task 2.3". Plans are scaffolding; commits live forever, and a later reader
  can't recover what the numbering meant.

Example:

```txt
Name the Run scan button as the app spells it

The quickstart said "Start scan", which no longer matches the button
in apps/web, so readers looked for a control that isn't there.
```

## Branches

- **`claude/<descriptive-name>`** is reserved for agent-led work. Claude Code
  always uses this prefix when it creates a branch on its own.
- **Human contributors** use any consistent name without the `claude/`
  prefix, such as `your-name/short-description`.
- Use kebab-case, short enough to read in a terminal.
- Never commit on `main`. `.claude/hooks/block-main-commits.sh` refuses
  commits, merges, rebases, cherry-picks, and reverts there.

## Pull requests

Mintlify deploys `docs.ilitylabs.com` on every push to `main`, so a pull
request is the only way a change reaches `main`.

- **Agents open every PR as a draft and flip it to ready themselves.** Mark
  it ready when, and only when, all four of these hold:

  1. The PR has had an **independent review**: a reviewer that did not write
     the change, working from its own checkout. See
     [`code-review.md`](code-review.md).
  2. Every blocking finding is **fixed**, or **dispositioned** to a GitHub
     issue and linked in a disposition comment on the PR. A critical bug or
     security issue is never deferred.
  3. Every CI check on the **head SHA** is green, with a non-zero check-run
     count. A PR pushed seconds ago has no checks yet, which trivially
     satisfies "every check is green".
  4. The branch merges cleanly into `main`. GitHub computes mergeability
     lazily, so a first read of `null` or `UNKNOWN` means retry, not proceed.

  Then tell the human the PR is ready to merge. Starting the review is part
  of opening the PR, not a follow-up to offer: this paragraph is standing
  authorization to run the review and post it, so don't ask first.
- **The body describes the change; comments carry the history.** Keep the
  body a description of the final state. Reviews, findings, and what was done
  about each belong in a review and a disposition comment.
- **Title** under about 70 characters, in the same imperative style as a
  commit subject.
- **Body** has three sections (`.github/PULL_REQUEST_TEMPLATE.md`):

  ```md
  ## Why

  <!-- What problem does this solve? Link to issue if applicable. -->

  ## What Changed

  <!-- Summary of the approach taken. -->

  ## How to Test

  <!-- Steps a reviewer can follow to verify behavior. -->
  ```

  For a change to how a page renders, add a `## Before / After` section with
  screenshots from `npx mint dev`.
- **AI agent attribution.** Commits made with significant agent involvement
  end with a `Co-Authored-By:` trailer naming the model actually used:

  ```txt
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

- **Merge with a merge commit.** Atomic commits only pay off when `main`
  keeps them, so `git bisect` and `git blame` land on one logical change. If
  a PR's commits aren't individually meaningful, such as a run of fixups,
  clean them up on the branch before merging.
- **No references to plan structure** in the title or body. Describe the
  work itself.

## Issues

- **Self-contained.** The title and body make sense without the context of
  the moment.
- **No references to plan structure.** Link the files the work touches
  instead.

## Pushing

- Use `git push -u origin <branch>` the first time, so later `git push` and
  `git pull` need no arguments.
- Push after each meaningful unit of work.
- Before pushing, run `npx markdownlint-cli2@0.17.2` and `npx mint broken-links`.
  CI runs markdownlint, and a green local run is not evidence the work is
  done.
- Force-push only your own branch, and only pinned to the SHA you read:
  `git push --force-with-lease=<branch>:<sha> origin HEAD:<branch>`.
  `.claude/hooks/guard-force-push.sh` refuses every other form.

## Things we don't do

- No pushing to `main`, force or otherwise.
- No skipping hooks (`--no-verify`) to get past a failing check. Fix the
  cause.
- No `git reset --hard` or other destructive operations without an explicit,
  clearly understood reason.
- No amending commits already pushed to a shared branch.
- No committing secrets or real API keys, even in examples. Use
  placeholders such as `$ILITY_API_KEY`.
- No hand edits to `api-reference/openapi.json`. Regenerate it with
  `scripts/build-openapi.py`.
