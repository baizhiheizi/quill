# HTTP API reference

> **30-second summary:** The API is mounted at `/api`, returns JSON, and authenticates via the `X-Access-Token` header (issued from the dashboard). Endpoints are stable but additive; breaking changes ship behind a version bump.

## Authentication

Generate an access token at [https://quill.im/dashboard/settings](https://quill.im/dashboard/settings) and pass it as `X-Access-Token`:

```http
GET /api/articles HTTP/1.1
Host: quill.im
X-Access-Token: <your-token>
```

## Conventions

All responses are JSON with ISO-8601 timestamps; pagination uses `limit` (capped at 100) and `offset`. Errors return a single `message` key — see [Errors](#errors).

## Endpoints

### `GET /api/articles`

List articles. The response shape depends on `author_id` or the caller's access.

| Param | Type | Notes |
|-------|------|-------|
| `author_id` | string (Mixin UUID) | Limit to articles by one author |
| `offset` | integer or ISO-8601 timestamp | Cursor. Pair with `order` for time-based pagination |
| `order` | `asc` \| `desc` | Direction. Defaults to popularity-sorted |
| `limit` | integer | Defaults to 20, capped at 100 |
| `query` | comma-separated tokens | Searches title, intro, tag names (Ransack `i_cont_any`) |

Example: [https://quill.im/api/articles?limit=5&order=asc&offset=2021-01-18T07:41:36.624Z&query=BTC,Xin](https://quill.im/api/articles?limit=5&order=asc&offset=2021-01-18T07:41:36.624Z&query=BTC,Xin)

### `GET /api/articles/:uuid`

Fetch a single article by UUID. Body gated by `ArticlePolicy#show?`; without a token, metadata only.

### `POST /api/articles`

Create a draft article. **Requires a valid access token.**

Article fields **must** nest under `article` (top-level → `400`); `tag_names` stays top-level and is forwarded to `CreateTagService` after the save.

Request body:

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
| `article.title` | yes | Plain string |
| `article.content` | yes | Markdown body |
| `article.intro` | no | Short summary |
| `article.price` | yes | Number, in the smallest unit of `asset_id` |
| `article.asset_id` | yes | One of the supported asset UUIDs (see `config/settings.yml`) |
| `tag_names` | no | Array of tag names; missing tags are created automatically |

On success, returns `{ "uuid": "f3a1..." }`. If the article publishes immediately, `article.publish!` runs before the response.

### `GET /api/valid_user_filter`

Returns the dashboard's reader-invitation validation rules.

### Catch-all

Unmatched paths fall through to `API::HomeController#index`, returning `{"message":"Not found"}` with `404`.

## Errors

Every error returns the same envelope — a single `message` string from [`API::RenderingHelper`](../../app/controllers/concerns/api/rendering_helper.rb). On `422`, the message joins `article.errors.full_messages` (not an `errors` array).

| Status | `message` body | When |
|--------|---------------|------|
| `400` | `"Bad request"` | `ActionController::ParameterMissing` (e.g. `POST /api/articles` without the `article` wrapper) |
| `401` | `"Unauthorized"` | Missing or invalid access token (where required) |
| `403` | `"Forbidden"` | Authenticated, but not allowed (e.g. `ArticlePolicy#show?` denies the body) |
| `404` | `"Not found"` | Resource not found, article not visible to caller, or unmatched `/api/*` path |
| `422` | `"<comma-joined errors.full_messages>"` | Validation error on the model |
| `5xx` | `"Internal server error"` | Server error — include the request ID when filing an issue |

## See also

- [Explanation → Architecture](../explanation/architecture.md)
- [Reference → Services](./services.md) — what runs behind the endpoints
- [README → API](../../README.md#api) — the original summary