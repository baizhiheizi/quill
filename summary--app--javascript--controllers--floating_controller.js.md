<!-- hash: size:2282 -->
# floating_controller summary

Mobile floating action bar shown/hidden by document scroll.

- Values: `showDelay` (Number, default 150), `hideDelay` (Number, default 500).
- `connect()`:
  - `this.show = debounce(this.show.bind(this), this.showDelayValue)`.
  - `this.hide = this.hide.bind(this)` (no debounce — must be the un-debounced reference used in setTimeout).
  - Stores `this.boundOnScroll` so it can be removed by reference later.
  - `document.addEventListener("scroll", this.boundOnScroll, { passive: true })`.
  - Removes initial `translate-x-24` class so the bar enters cleanly.
- `boundOnScroll` triggers `show()`, clears pending hide timer, schedules new `hide()` via `setTimeout`.
- `disconnect()` removes the exact stored scroll listener reference and clears `this.hideTimer` if pending.
- `show()` adds `translate-y-24`; `hide()` removes it.

Energy notes (in file header): debounce wraps the *function*, not its return value; non-passive scroll listeners are scroll-blocking.