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
- Errors return a JSON object with a `message` key and the appropriate HTTP status (see [Errors](#errors)).

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

The request body must be wrapped in an `article` key — the controller calls `params.require(:article).permit(...)`, so a top-level `title` / `content` will be rejected with `400 Bad Request` from `ActionController::ParameterMissing`. `tag_names` lives at the top level because it is not a permitted attribute on the article; the controller forwards it to `CreateTagService` after the article is saved.

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
| `tag_names` | no | Array of tag names; missing tags are created automatically via `CreateTagService` |

On success, returns the new article's UUID with HTTP `201 Created`:

```json
{ "uuid": "f3a1..." }
```

If the article publishes immediately, `article.publish!` is called and the article moves to `published` state before the response is returned.

### `GET /api/files/:hash`

Fetch a file from the asset CDN by its hash.

### `GET /api/valid_user_filter`

Returns the validation rules used by the dashboard when inviting new readers. Useful for clients that want to mirror the same checks.

### Catch-all

Any unmatched path under `/api` falls through to `API::HomeController#index`, which renders a `404 Not Found` with `{ "message": "Not found" }`. There is no service-metadata landing page.

## Errors

| Status | Meaning |
|--------|---------|
| `400` | Missing required parameter — body is `{ "message": "param is missing or the value is empty: article" }` (raised by `ActionController::ParameterMissing`) |
| `401` | Missing or invalid access token (where required) — body is `{ "message": "Unauthorized" }` |
| `403` | Authenticated, but not allowed (e.g. `ArticlePolicy#show?` denies the body) — body is `{ "message": "Forbidden" }` |
| `404` | Resource not found (record not found, or article not visible to caller) — body is `{ "message": "Not found" }` |
| `422` | Validation error from the model — body is `{ "message": "Unprocessable entity" }` (in non-local environments the model errors are not echoed; check the server log) |
| `5xx` | Server error — body is `{ "message": "Internal server error" }` in production; in local environments the original exception message is included |

Every error response is shaped `{ "message": <string> }` by [`API::RenderingHelper`](../../app/controllers/concerns/api/rendering_helper.rb); clients should parse `message` (not `error` or `errors`).

## See also

- [Explanation → Architecture](../explanation/architecture.md)
- [Reference → Services](./services.md) — what runs behind the API endpoints
- [README → API](../../README.md#api) — the original, terse summary