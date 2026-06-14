<!-- hash: size:953 -->
# app/javascript/controllers/infinite_scroll_controller.js

IntersectionObserver-driven "load next page" for index lists.

- Targets: `scrollArea`, `pagination`.
- `connect()` → `createObserver()`: builds an `IntersectionObserver` with
  thresholds `[0, 1.0]` and observes `scrollAreaTarget` if present.
- `handleIntersect(entries)`: for each intersecting entry, calls `loadMore()`.
- `loadMore()`: reads `a` from `paginationTarget`, `get(next.href, ...)` with
  `responseKind: "turbo-stream"`.

Note: locally this file is the pre-cleanup version. The post-cleanup shape
(stored `this.observer`, `disconnect()`, in-flight + lastFetchedHref dedup)
is not present in this checkout.
