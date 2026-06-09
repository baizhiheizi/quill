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

Request body:

```json
{
  "title": "article title",
  "content": "some article content",
  "intro": "some article introduction",
  "price": 0.000001,
  "asset_id": "c6d0c728-2624-429b-8e0d-d9d19b6592fa",
  "tag_names": ["BTC", "Blockchain"]
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `title` | yes | Plain string |
| `content` | yes | Markdown body |
| `intro` | no | Short summary |
| `price` | yes | Number, in the smallest unit of `asset_id` |
| `asset_id` | yes | One of the supported asset UUIDs (see `config/settings.yml`) |
| `tag_names` | no | Array of tag names; missing tags are created automatically |

On success, returns the new article's UUID:

```json
{ "uuid": "f3a1..." }
```

If the article publishes immediately, `article.publish!` is called and the article moves to `published` state before the response is returned.

### `GET /api/files/:hash`

Fetch a file from the asset CDN by its hash.

### `GET /api/valid_user_filter`

Returns the validation rules used by the dashboard when inviting new readers. Useful for clients that want to mirror the same checks.

### Catch-all

Any unmatched path under `/api` falls through to `API::HomeController#index`, which returns service metadata.

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