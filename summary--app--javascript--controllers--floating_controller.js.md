size:2282
# floating_controller summary

Shows a mobile floating action bar on scroll, hides it after idle.

- Stimulus values: `showDelay` (150 ms), `hideDelay` (500 ms).
- `connect()` stores `this.boundOnScroll` (a bound closure) and registers a `{ passive: true }` document-level `scroll` listener; removes `translate-x-24` immediately.
- `show()` is wrapped in `underscore.debounce` to coalesce DOM writes; `hideTimer` is reset on every scroll event.
- `disconnect()` is the cleanup template: removes the stored scroll listener reference and clears the pending `hideTimer` so multiple Turbo navigations don't accumulate listeners.
- Comment block documents the energy / lifecycle reasons for each decision.
