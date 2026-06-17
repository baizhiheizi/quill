# HTTP API reference

> **30-second summary:** The API is mounted at `/api` and returns JSON only. Authenticate with an access token issued from the dashboard (`X-Access-Token` header). The root URL is `https://quill.im/api`. Endpoints are stable but additive; breaking changes ship behind a version bump.

## Authentication

Generate an access token at [https://quill.im/dashboard/settings](https://quill.im/dashboard/settings) and pass it as a request header:

```http
GET /api/articles HTTP/1.1
Host: quill.im
X-Access-Token: <your-token>
```

Without a valid token, `GET /articles/:uuid` returns metadata only; the body is gated by `ArticlePolicy#show?` (author or paid reader only).

## Conventions

All responses are JSON, timestamps are ISO-8601 UTC, pagination uses `limit` (capped at `100`) and `offset`. Errors return a single `message` key with the appropriate HTTP status — see [Errors](#errors).

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

Fetch a single article by UUID. Body is gated by `ArticlePolicy#show?` (see [Authentication](#authentication)).

### `POST /api/articles`

Create a draft article. **Requires a valid access token.**

Article fields **must** nest under an `article` key (`API::ArticlesController#article_params`); top-level fields return `400 Bad Request`. `tag_names` stays top-level (not an `Article` attribute) and is forwarded to `CreateTagService` after the save.

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

On success, returns the new article's UUID:

```json
{ "uuid": "f3a1..." }
```

If the article publishes immediately, `article.publish!` runs before the response.

### `GET /api/valid_user_filter`

Returns the validation rules the dashboard uses when inviting readers — useful for clients that want to mirror those checks.

### Catch-all

Unmatched paths fall through to `API::HomeController#index`, which returns `{"message":"Not found"}` with `404`. There is no service metadata index.

## Errors

Every error returns the same envelope — a single `message` string — produced by [`API::RenderingHelper`](../../app/controllers/concerns/api/rendering_helper.rb). On `422`, `article.errors.full_messages` is joined into the message (not an `errors` array).

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