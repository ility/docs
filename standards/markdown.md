# Markdown standards

Conventions for every Markdown and MDX file in `ility/docs`: the published
pages, `AGENTS.md`, `README.md`, and these standards. They match
[`ility/ility`'s `docs/standards/markdown.md`](https://github.com/ility/ility/blob/main/docs/standards/markdown.md),
minus the ADR and plan formats, which this repo doesn't use.
`.markdownlint-cli2.jsonc` enforces the mechanical rules; run
`npx markdownlint-cli2@0.17.2`. Wording, terminology, and voice for customer pages
live in [`AGENTS.md`](../AGENTS.md).

## General

- One blank line between sections. End the file with a single newline.
- Write in plain language. Contributors of every experience level read these
  documents, not only the people who wrote them.
- Prefer short paragraphs. If a sentence needs a sub-clause to qualify every
  noun, restructure it.
- Use US English.

## Headings

- **H1** is the file title. One per file, at the top. On an MDX page the
  frontmatter `title` is the H1, so the body starts at H2.
- **H2** for top-level sections, **H3** for sub-sections when the content
  genuinely nests.
- Don't skip levels (no jumping from H2 to H4).
- Use sentence case, not title case.

## Code fences

Always give a language tag. An untagged fence loses highlighting and makes
the intent ambiguous. Use `text` for plain output.

| Tag     | Use for                                    |
| ------- | ------------------------------------------ |
| `bash`  | Shell commands, including `curl` examples  |
| `json`  | JSON request and response bodies           |
| `ts`    | TypeScript and JavaScript                  |
| `yaml`  | CI configuration                           |
| `md`    | Markdown snippets inside a Markdown file   |
| `text`  | Plain output, such as tab-separated rows   |

Tabs are fine inside a fence when the output they show is tab-separated.
Don't use them in prose.

## Tables and lists

**Tables** are for matrices and index-style references where each column
carries distinct meaning. Don't use a table for narrative that reads as
prose.

**Bullet lists** are for items with no implied order. **Numbered lists** are
for procedures where step N depends on step N−1.

If each list item needs a sentence of explanation, use a **bold term** and a
colon.

## Links

Use descriptive link text that tells the reader where they're going.

```md
<!-- Good -->

See [Connect the MCP server](/mcp/connect) for setup.

<!-- Avoid -->

See [here](/mcp/connect) for more.
```

On published pages, link to other pages by their root-relative path without
the extension (`/mcp/connect`), which `npx mint broken-links` checks. In
`AGENTS.md` and these standards, use relative file paths. Link to other repos and
sites with full URLs. Never leave a bare URL: wrap it in `<…>` or give it
link text.

## MDX components

Mintlify components (`<Steps>`, `<Tabs>`, `<Update>`, `<Note>`) indent the
Markdown inside them. That indent is fine, and the lint config doesn't flag
it. Keep the Markdown inside a component to the same rules as the rest of the
page.
