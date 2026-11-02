# ility customer docs — instructions for AI agents

This repository is the customer-facing documentation for **ility**, published by
Mintlify at [docs.ilitylabs.com](https://docs.ilitylabs.com). Every push to `main` deploys.

- Pages are MDX files with YAML frontmatter. Navigation and branding live in
  `docs.json`.
- The product lives in a separate repository, `ility/ility`. Ground every claim
  in that code: the UI copy in `apps/web`, the API in `apps/api`, and the specs
  in `docs/specs`. Don't document a feature from memory or from a plan.
- `api-reference/openapi.json` is generated. Don't edit it by hand. Run
  `python3 scripts/build-openapi.py <path to ility>/apps/api/openapi.json`, and
  change the curated list of operations in that script.
- Preview locally with `npx mint dev`, and check links with `npx mint broken-links`.

## Audience

Customers: people who test and fix websites, and the developers who connect ility
to CI, scripts, and AI assistants. Not ility's own engineers. Leave out internal
architecture, infrastructure, and anything only staff can do.

## Terminology

- The product is **ility**, always lowercase, even at the start of a sentence.
  The company is **Ility Labs**.
- **Workspace**: the account a team shares. Not "organization" or "project".
- **Surface**: one thing ility tests, today always a website. The API addresses
  the website behind a surface as a **domain**, by its slug.
- **Issue** and **instance**: one problem with one fix, and each place it appears.
- Roles are **owner**, **member**, and **viewer**.
- Issue statuses are **Open**, **Resolved**, **Won't fix**, and **False positive**.
- Severities are **critical**, **serious**, **moderate**, and **minor**.

## Style

- US English. Active voice, second person ("you").
- Short sentences, one idea each. Sentence case for headings.
- Bold for UI labels, exactly as the app spells them: choose **Run scan**.
- Code formatting for URLs, paths, fields, and values.
- Don't promise prices, plan limits, or dates. Link to the app for anything
  billing-related.
