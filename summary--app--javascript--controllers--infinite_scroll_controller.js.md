<!-- hash: size:953 -->
# infinite_scroll_controller summary

Auto-pagination via `IntersectionObserver`.

- Targets: `scrollArea`, `pagination` (anchor list).
- `connect()` initializes `loading=false`, `lastFetchedHref=null`, calls `createObserver()`.
- `createObserver()` builds `IntersectionObserver` with `threshold: [0, 1.0]` and observes `scrollAreaTarget` if present.
- `disconnect()` calls `observer.disconnect()` and nulls it (mandatory cleanup).
- `handleIntersect` triggers `loadMore()` when any entry is intersecting.
- `loadMore()` is async, idempotent (`loading` flag, `lastFetchedHref` guard). Fetches next href with `get(url, { contentType: "application/json", responseKind: "turbo-stream" })`.