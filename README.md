# ility docs

The source for [docs.ilitylabs.com](https://docs.ilitylabs.com), the customer
documentation for ility. Mintlify deploys `main` on every push.

## Preview locally

```bash
npx mint dev
```

Then open <http://localhost:3000>. Check links with `npx mint broken-links`.

## API reference

`api-reference/openapi.json` is generated from the app's OpenAPI document. After
the API changes, rebuild it from a checkout of `ility/ility`:

```bash
python3 scripts/build-openapi.py ../ility/apps/api/openapi.json
```

To add an endpoint to the reference, add it to `OPERATIONS` in
`scripts/build-openapi.py`.

## Writing guidelines

See [`AGENTS.md`](AGENTS.md) for terminology and style.
