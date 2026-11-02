#!/usr/bin/env python3
"""Build api-reference/openapi.json from the app's full OpenAPI document.

The app (github.com/ility/ility) publishes every /v1 route in
apps/api/openapi.json, including routes that only the web app uses. The
customer API reference documents a curated subset: the routes an API key can
call to read results and start scans. This script copies those operations,
adds the summaries, descriptions, server, and auth scheme the reference
shows, and keeps only the component schemas they reference.

Usage:
    python3 scripts/build-openapi.py path/to/ility/apps/api/openapi.json

Rerun it whenever the app's API changes, and commit the result.
"""
import json
import sys
from pathlib import Path

# (path, method) -> (tag, summary, description)
OPERATIONS = {
    ("/v1/me/workspaces", "get"): (
        "Workspaces",
        "List workspaces",
        "Lists the workspaces the caller belongs to. An API key only ever sees its own workspace.",
    ),
    ("/v1/surfaces", "get"): (
        "Surfaces",
        "List surfaces",
        "Lists the workspace's surfaces with each one's score, open issue count, and last scan.",
    ),
    ("/v1/surfaces/{id}", "get"): (
        "Surfaces",
        "Get a surface",
        "Returns one surface, including the domain it wraps and that domain's slug.",
    ),
    ("/v1/domains", "get"): (
        "Domains",
        "List domains",
        "Lists the websites in the workspace. Use a domain's `slug` with the other domain routes and its `id` to filter issues.",
    ),
    ("/v1/domains/{slug}", "get"): (
        "Domains",
        "Get a domain",
        "Returns one domain's settings, plan, and entitlements.",
    ),
    ("/v1/domains/{slug}/summary", "get"): (
        "Domains",
        "Get a domain summary",
        "Returns the domain's accessibility score and band, open issue counts by severity and WCAG level, page counts, and its last scan.",
    ),
    ("/v1/domains/{slug}/scans", "get"): (
        "Scans",
        "List a domain's scans",
        "Lists scan runs for one domain, newest first.",
    ),
    ("/v1/domains/{slug}/scans", "post"): (
        "Scans",
        "Start a scan",
        "Queues a scan of the domain's pages and returns one scan run per engine. "
        "Omit the body to scan every active page with the domain's own WCAG target and engines. "
        "With an API key, the domain's plan must include API triggers, or the request fails with `403` and `reason: api_triggers_not_entitled`.",
    ),
    ("/v1/scans", "get"): (
        "Scans",
        "List scans",
        "Lists scan runs across the workspace, newest first. Filter by `status` (`active` means queued, running, or paused) or by domain slug.",
    ),
    ("/v1/scans/{id}", "get"): (
        "Scans",
        "Get a scan",
        "Returns one scan run with its status, page counts, score, and timing. Poll it to follow a scan you started.",
    ),
    ("/v1/scans/{id}/pages", "get"): (
        "Scans",
        "List a scan's pages",
        "Lists the pages in one scan run with each page's result, score, and any failure reason.",
    ),
    ("/v1/issues", "get"): (
        "Issues",
        "List issues",
        "Lists issues across the workspace. Without a `status` filter, only open issues are returned. Paginate with `page` and `limit`; `total` counts every match.",
    ),
    ("/v1/issues/{id}", "get"): (
        "Issues",
        "Get an issue",
        "Returns one issue with its rule, WCAG criteria, severity, status, assignee, and page and instance counts.",
    ),
    ("/v1/issues/{id}", "patch"): (
        "Issues",
        "Update an issue",
        "Changes an issue's status, assignee, or external link. A status change can carry a short note, which appears on the timeline.",
    ),
    ("/v1/issues/{id}/instances", "get"): (
        "Issues",
        "List an issue's instances",
        "Lists every place the issue appears: the page, the element's selector, and its markup.",
    ),
    ("/v1/issues/{id}/fix-prompt", "get"): (
        "Issues",
        "Get a fix prompt",
        "Returns a ready-made prompt that describes the issue, the failing markup, and how to fix it, for a coding assistant working in the site's codebase.",
    ),
    ("/v1/issues/{id}/recheck", "post"): (
        "Issues",
        "Re-check an issue",
        "Rescans the pages where the issue appears. With an API key, the domain's plan must include API triggers.",
    ),
}

TAG_ORDER = ["Workspaces", "Surfaces", "Domains", "Scans", "Issues"]


def collect_refs(node, found):
    if isinstance(node, dict):
        ref = node.get("$ref")
        if isinstance(ref, str) and ref.startswith("#/components/schemas/"):
            found.add(ref.rsplit("/", 1)[1])
        for value in node.values():
            collect_refs(value, found)
    elif isinstance(node, list):
        for value in node:
            collect_refs(value, found)


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    source = json.loads(Path(sys.argv[1]).read_text())
    schemas = source.get("components", {}).get("schemas", {})

    paths: dict = {}
    for (path, method), (tag, summary, description) in OPERATIONS.items():
        try:
            operation = dict(source["paths"][path][method])
        except KeyError:
            sys.exit(f"{method.upper()} {path} is missing from {sys.argv[1]}")
        operation.update(tags=[tag], summary=summary, description=description)
        paths.setdefault(path, {})[method] = operation

    # Keep only the schemas the chosen operations reach, following nested refs.
    keep: set = set()
    pending: set = set()
    collect_refs(paths, pending)
    while pending:
        name = pending.pop()
        if name in keep:
            continue
        keep.add(name)
        collect_refs(schemas[name], pending)

    document = {
        "openapi": source.get("openapi", "3.1.0"),
        "info": {
            "title": "ility API",
            "version": source.get("info", {}).get("version", "1.0.0"),
            "description": "Read accessibility results and start scans in your ility workspace.",
        },
        "servers": [{"url": "https://app.ilitylabs.com"}],
        "security": [{"apiKey": []}],
        "tags": [{"name": tag} for tag in TAG_ORDER],
        "paths": paths,
        "components": {
            "securitySchemes": {
                "apiKey": {
                    "type": "http",
                    "scheme": "bearer",
                    "description": "An ility API key, such as `ilk_1a2b3c4d_…`. Workspace owners create keys under Settings → API keys.",
                }
            },
            "schemas": {name: schemas[name] for name in sorted(keep)},
        },
    }
    out = Path(__file__).resolve().parent.parent / "api-reference" / "openapi.json"
    out.write_text(json.dumps(document, indent=2) + "\n")
    print(f"Wrote {len(OPERATIONS)} operations and {len(keep)} schemas to {out}")


if __name__ == "__main__":
    main()
