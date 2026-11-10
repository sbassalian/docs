# Growi Docs

Source for the Growi developer docs at https://growi.mintlify.app, built with
[Mintlify](https://mintlify.com). Pushing to `main` deploys.

## Layout

| Path | What's there |
| --- | --- |
| `docs.json` | Site config and the sidebar (tabs: Guides, AI & MCP, API reference, Webhooks) |
| `index.mdx`, `snippets/home.jsx` | The homepage |
| `essentials/` | Guides: integrations, reporting, Meta ads, Connect Claude |
| `ai/` | AI & MCP tab: MCP tool reference and Juno |
| `api-reference/` | Overview pages (introduction, auth, rate limits, conventions, child brands, changelog) |
| `api-reference/endpoint/` | One page per endpoint |
| `api-reference/openapi.json` | The main OpenAPI spec |
| `api-reference/tik-tok-shop-openapi.json` | The TikTok Shop spec (generated) |
| `webhooks/` | Webhook payloads, examples and troubleshooting |
| `scripts/` | Generators and checks, below |

## Local preview

```bash
npm i -g mint
mint dev               # http://localhost:3000
```

## Checks

Run these before opening a PR:

```bash
mint broken-links         # links between pages
mint validate             # content, OpenAPI specs and a strict build
ruby scripts/check_nav.rb # every nav page has a file, every openapi: ref is in a spec, no orphan pages
```

## Generated endpoints

Don't hand-edit generated pages or operations. Change the inputs and rerun.

**Backend public API.** `scripts/sync_openapi.rb` copies the allow-listed paths in
`scripts/openapi_public_paths.yml` from the backend's rswag spec into
`api-reference/openapi.json` and writes their pages:

```bash
ruby scripts/sync_openapi.rb ../backend/swagger/v1/swagger.yaml
```

- Only operations the script generated (marked `x-generated-by`) are replaced. Older
  endpoints are still written by hand in `openapi.json`. To move one over, delete it
  there and add it to the allow-list.
- Entries with `pending: true` haven't shipped yet. Their "Soon" pages stay until
  the backend spec has them.
- The run writes nothing if an internal term would reach the docs. Put public wording
  under `texts:` in the allow-list.

**TikTok Shop.** `scripts/gen_tik_tok_shop.rb` builds `tik-tok-shop-openapi.json`,
the pages in `api-reference/endpoint/tik-tok-shop/` and the TikTok Shop nav group
from the backend route table and the TikTok Shop service's spec. Wording lives in
`scripts/tik_tok_shop_overrides.yml`.

```bash
ruby scripts/gen_tik_tok_shop.rb
```

## Deprecating an endpoint

Deprecated endpoints are hidden from the docs, not deleted, so old links still load
while new readers never find them.

1. Add `deprecated: true` and `hidden: true` to the page's frontmatter.
2. Add `"deprecated": true` and `"x-hidden": true` to the operation in the spec.
3. Add a `<Warning>` at the top of the page that links the replacement.
4. Take the page out of the navigation in `docs.json`.
5. Add a row to the deprecations table in `api-reference/changelog.mdx`, naming the
   old path as plain code (no link) and linking the replacement.
6. Remove links to the page from every other page. `ruby scripts/check_nav.rb` fails
   while one remains.
