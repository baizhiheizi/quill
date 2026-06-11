# HTTP API reference

> **30-second summary:** The API is mounted at `/api` and returns JSON only. Authenticate with an access token issued from the dashboard (`X-Access-Token` header). The root URL is `https://quill.im/api`. Endpoints are stable but additive; breaking changes ship behind a version bump.

## Authentication

Generate an access token at [https://quill.im/dashboard/settings](https://quill.im/dashboard/settings) and pass it as a request header:

```http
GET /api/articles HTTP/1.1
Host: quill.im
X-Access-Token: <your-token>
```

Without a valid token, `GET /articles/:uuid` returns article metadata but **not** the body. To read the body you must be the author or a paid reader of that article (enforced by `ArticlePolicy#show?`).

## Conventions

- All responses are JSON.
- Timestamps are ISO-8601 strings in UTC.
- Pagination uses `limit` and `offset`. `limit` is clamped to `100`.
- Errors return a JSON object with an `error` key and the appropriate HTTP status.

## Endpoints

### `GET /api/articles`

List articles. The response shape depends on whether `author_id` or an access token is supplied.

| Param | Type | Notes |
|-------|------|-------|
| `author_id` | string (Mixin UUID) | Limit to articles by one author |
| `offset` | integer or ISO-8601 timestamp | Cursor. Pair with `order` for time-based pagination |
| `order` | `asc` \| `desc` | Direction. Defaults to popularity-sorted |
| `limit` | integer | Defaults to 20, capped at 100 |
| `query` | comma-separated tokens | Searches title, intro, tag names (Ransack `i_cont_any`) |

Example: [https://quill.im/api/articles?limit=5&order=asc&offset=2021-01-18T07:41:36.624Z&query=BTC,Xin](https://quill.im/api/articles?limit=5&order=asc&offset=2021-01-18T07:41:36.624Z&query=BTC,Xin)

### `GET /api/articles/:uuid`

Fetch a single article by UUID. Body is only included for authorized readers (see [Authentication](#authentication)).

### `POST /api/articles`

Create a draft article. **Requires a valid access token.**

The endpoint uses Rails' strong-parameters and expects the article attributes under an `article` key, with `tag_names` passed as a sibling field:

```json
{
  "article": {
    "title": "article title",
    "content": "some article content",
    "intro": "some article introduction",
    "price": 0.000001,
    "asset_id": "c6d0c728-2624-429b-8e0d-d9d19b6592fa"
  },
  "tag_names": ["BTC", "Blockchain"]
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `article[title]` | yes | Plain string |
| `article[content]` | yes | Markdown body |
| `article[intro]` | no | Short summary |
| `article[price]` | yes | Number, in the smallest unit of `asset_id` |
| `article[asset_id]` | yes | One of the supported asset UUIDs (see `config/settings.yml` → `supported_assets`) |
| `tag_names` | no | Array of tag names; missing tags are created automatically via `CreateTagService` |

On success, returns the new article's UUID:

```json
{ "uuid": "f3a1..." }
```

If the article is eligible to publish immediately (`may_publish?`), `article.publish!` is called and the article moves to `published` state before the response is returned. Tag reconciliation runs before publishing.

### `GET /api/files/:hash`

Fetch a file from the asset CDN by its hash. Backed by `ArticleSnapshot` (see [`MarkdownRenderService`](./services.md#markdownrenderservice--app servicesmarkdown_render_service-rb)).

### `GET /api/valid_user_filter`

Check whether a Mixin user is an established participant on Quill — i.e. has either paid for an article or published one. The dashboard uses this to filter who is allowed to receive tips / rewards.

| Param | Type | Notes |
|-------|------|-------|
| `user_id` | string (Mixin UUID) | The user to check |
| `type` | `recent` \| (omitted) | `recent` restricts paid / published activity to the last 7 days; omitting `type` checks lifetime activity |

Response:

```json
{ "approved": true }
```

Returns `approved: false` when the user is unknown, or when no qualifying activity is found.

### Catch-all

Any unmatched path under `/api` falls through to `API::HomeController#index`, which renders an HTTP `404` (via `render_not_found` in the API base controller). The namespace root (`/api/`) also routes there.

## Errors

| Status | Meaning |
|--------|---------|
| `401` | Missing or invalid access token (where required) |
| `403` | Authenticated, but not allowed (e.g. `ArticlePolicy#show?` denies the body) |
| `404` | Resource not found (record not found, or article not visible to caller) |
| `422` | Validation error — the response body carries `errors` from the model |
| `5xx` | Server error — surface the request ID when filing an issue |

## See also

- [Explanation → Architecture](../explanation/architecture.md)
- [Reference → Services](./services.md) — what runs behind the API endpoints
- [README → API](../../README.md#api) — the original, terse summary