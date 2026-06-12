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

The article fields **must** be nested under an `article` key (see `API::ArticlesController#article_params`). Top-level fields are rejected with `400 Bad Request` from `ActionController::ParameterMissing`. `tag_names` stays at the top level because it is not a permitted attribute on `Article` — the controller forwards it to `CreateTagService` after the article is saved.

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

If the article publishes immediately, `article.publish!` is called and the article moves to `published` state before the response is returned.

### `GET /api/files/:hash`

Fetch a file from the asset CDN by its hash.

### `GET /api/valid_user_filter`

Returns the validation rules used by the dashboard when inviting new readers. Useful for clients that want to mirror the same checks.

### Catch-all

Any unmatched path under `/api` falls through to `API::HomeController#index`, which simply renders a 404 (`{"message":"Not found"}`) — there is no service metadata index.

## Errors

Every API error returns the same JSON envelope: a single `message` string. This is produced by [`API::RenderingHelper`](../../app/controllers/concerns/api/rendering_helper.rb) — the helper centralises status, body shape, and default copy. `422 Unprocessable Entity` carries `article.errors.full_messages` joined into the message, **not** an `errors` array as some clients expect.

| Status | `message` body | When |
|--------|---------------|------|
| `400` | `"Bad request"` | `ActionController::ParameterMissing` (e.g. `POST /api/articles` without the `article` wrapper) |
| `401` | `"Unauthorized"` | Missing or invalid access token (where required) |
| `403` | `"Forbidden"` | Authenticated, but not allowed (e.g. `ArticlePolicy#show?` denies the body) |
| `404` | `"Not found"` | Resource not found, article not visible to caller, or unmatched `/api/*` path |
| `422` | `"<comma-joined errors.full_messages>"` | Validation error on the model |
| `5xx` | `"Internal server error"` | Server error — surface the request ID when filing an issue |

## See also

- [Explanation → Architecture](../explanation/architecture.md)
- [Reference → Services](./services.md) — what runs behind the API endpoints
- [README → API](../../README.md#api) — the original, terse summary