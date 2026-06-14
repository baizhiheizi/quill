size:471
# autosave_controller summary

Debounced form auto-submission.

- Targets: `form`; value: `delay` (Number).
- `initialize()` binds `this.save`.
- `connect()` re-binds `this.save = debounce(this.save, this.delayValue)` if `delay > 0`.
- `save()` early-returns unless `window._rails_loaded` is true, then calls `this.formTarget.requestSubmit()`.
