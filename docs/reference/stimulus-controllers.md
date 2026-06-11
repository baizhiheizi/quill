# Stimulus controllers reference

> **30-second summary:** Quill's frontend is wired by [Stimulus](https://stimulus.hotwired.dev/) controllers in [`app/javascript/controllers/`](../../app/javascript/controllers/). Each `*_controller.js` exports a default class for one behaviour; the manifest in [`index.js`](../../app/javascript/controllers/index.js) maps `data-controller="…"` to those classes. Listeners attached outside `this.element` **must** be removable from `disconnect()` so Turbo navigations do not leak handlers.

## Conventions

- **One controller per file** in [`app/javascript/controllers/`](../../app/javascript/controllers/), named `<snake_case>_controller.js`.
- **Identifier mapping** lives in `index.js`: `application.register("floating", FloatingController)` binds `data-controller="floating"`. Regenerate after add/rename with `./bin/rails stimulus:manifest:update`.
- **Lifecycle:** implement `initialize()`, `connect()`, `disconnect()`. Anything registered in `connect()` (observers, intervals, document-level listeners) **must** be torn down in `disconnect()`.
- **Bound references:** store handlers as instance properties (`this.boundOnScroll = …`) so `disconnect()` can pass the same reference to `removeEventListener`. Inline arrow functions cannot be removed.
- **Values/targets:** declare `static values` and `static targets`; consume via `this.<name>Value` and `this.has<Name>Target` / `this.<name>Target`.
- **Reuse utilities** in [`app/javascript/utils/`](../../app/javascript/utils/) (`toast`, `notify`, `uploader`) and [`stimulus-use`](https://github.com/stimulus-use/stimulus-use) mixins (`useHover`, `useTransition`).

## Catalog

Every controller registered in `app/javascript/controllers/index.js`, with its source file and a one-line purpose. Read the source for full behaviour — controllers stay short on purpose.

| Identifier | File | Purpose |
|------------|------|---------|
| `article-form` | [`article_form_controller.js`](../../app/javascript/controllers/article_form_controller.js) | Article drafting form (markdown editor + price/asset fields) |
| `auto-hide` | [`auto_hide_controller.js`](../../app/javascript/controllers/auto_hide_controller.js) | Hides an element after a configurable delay |
| `auto-refresh` | [`auto_refresh_controller.js`](../../app/javascript/controllers/auto_refresh_controller.js) | Triggers a Turbo refresh on a timer |
| `autosave` | [`autosave_controller.js`](../../app/javascript/controllers/autosave_controller.js) | Persists form drafts while typing |
| `clipboard` | [`clipboard_controller.js`](../../app/javascript/controllers/clipboard_controller.js) | Copies a target value to the clipboard |
| `collections-form-component` | [`collections_form_component_controller.js`](../../app/javascript/controllers/collections_form_component_controller.js) | Author-side collection editing UI |
| `comment-form` | [`comment_form_controller.js`](../../app/javascript/controllers/comment_form_controller.js) | Comment composer (inline validation, optimistic render) |
| `darkmode` | [`darkmode_controller.js`](../../app/javascript/controllers/darkmode_controller.js) | Theme toggle persisted to local storage |
| `dropdown` | [`dropdown_controller.js`](../../app/javascript/controllers/dropdown_controller.js) | Open/close menu with enter/leave transitions |
| `eth-wallet` | [`eth_wallet_controller.js`](../../app/javascript/controllers/eth_wallet_controller.js) | Ethereum (MVM) wallet glue for EIP-1193 providers |
| `fennec` | [`fennec_controller.js`](../../app/javascript/controllers/fennec_controller.js) | FenneC wallet integration |
| `flash` | [`flash_controller.js`](../../app/javascript/controllers/flash_controller.js) | Dismissible flash banners |
| `floating` | [`floating_controller.js`](../../app/javascript/controllers/floating_controller.js) | Mobile floating action bar that shows on scroll |
| `flyonui-dropdown` | [`flyonui_dropdown_controller.js`](../../app/javascript/controllers/flyonui_dropdown_controller.js) | FlyonUI-themed dropdown wrapper |
| `modal-component` | [`flyonui_modal_controller.js`](../../app/javascript/controllers/flyonui_modal_controller.js) | FlyonUI-themed modal wrapper. Registered as `modal-component` in the manifest (not `flyonui-modal`); partials use `data-controller="modal-component"`. |
| `hljs` | [`hljs_controller.js`](../../app/javascript/controllers/hljs_controller.js) | Highlight.js runner triggered on visible code blocks |
| `infinite-scroll` | [`infinite_scroll_controller.js`](../../app/javascript/controllers/infinite_scroll_controller.js) | Paginates via `IntersectionObserver` |
| `load-more` | [`load_more_controller.js`](../../app/javascript/controllers/load_more_controller.js) | Click-to-load pagination button |
| `login` | [`login_controller.js`](../../app/javascript/controllers/login_controller.js) | Login form state (provider switching) |
| `modal` | [`modal_controller.js`](../../app/javascript/controllers/modal_controller.js) | Generic modal show/hide logic |
| `mvm-deposit` | [`mvm_deposit_controller.js`](../../app/javascript/controllers/mvm_deposit_controller.js) | MVM deposit flow state |
| `mvm-pay-button-component` | [`mvm_pay_button_component_controller.js`](../../app/javascript/controllers/mvm_pay_button_component_controller.js) | MVM "pay" button subcomponent |
| `nested-form` | [`nested_form_controller.js`](../../app/javascript/controllers/nested_form_controller.js) | Add/remove nested form rows |
| `photoswipe` | [`photoswipe_controller.js`](../../app/javascript/controllers/photoswipe_controller.js) | PhotoSwipe gallery wiring |
| `pre-orders-form-component` | [`pre_orders_form_component_controller.js`](../../app/javascript/controllers/pre_orders_form_component_controller.js) | Pre-order authoring form |
| `pre-orders-mixpay-button-component` | [`pre_orders_mixpay_button_component_controller.js`](../../app/javascript/controllers/pre_orders_mixpay_button_component_controller.js) | MixPay button inside pre-order form |
| `pre-orders-pay-button-component` | [`pre_orders_pay_button_component_controller.js`](../../app/javascript/controllers/pre_orders_pay_button_component_controller.js) | Generic "pay" button inside pre-order form |
| `pre-orders-payment-component` | [`pre_orders_payment_component_controller.js`](../../app/javascript/controllers/pre_orders_payment_component_controller.js) | Pre-order payment summary panel |
| `pre-orders-state-component` | [`pre_orders_state_component_controller.js`](../../app/javascript/controllers/pre_orders_state_component_controller.js) | Pre-order status pill |
| `prefetch` | [`prefetch_controller.js`](../../app/javascript/controllers/prefetch_controller.js) | Hover-driven Turbo prefetch. Values: `debounce-delay` (ms, default `150`). |
| `preview-upload` | [`preview_upload_controller.js`](../../app/javascript/controllers/preview_upload_controller.js) | Local image preview before upload |
| `qrcode-component` | [`qrcode_component_controller.js`](../../app/javascript/controllers/qrcode_component_controller.js) | Renders QR codes for deposit addresses |
| `references-select` | [`references_select_controller.js`](../../app/javascript/controllers/references_select_controller.js) | Cross-article reference picker |
| `reload` | [`reload_controller.js`](../../app/javascript/controllers/reload_controller.js) | One-shot Turbo reload trigger |
| `scroll-to` | [`scroll_to_controller.js`](../../app/javascript/controllers/scroll_to_controller.js) | Smooth-scroll to a hash target |
| `search` | [`search_controller.js`](../../app/javascript/controllers/search_controller.js) | Debounced article search box |
| `select-currency` | [`select_currency_controller.js`](../../app/javascript/controllers/select_currency_controller.js) | Currency picker for pre-orders |
| `select-menu` | [`select_menu_controller.js`](../../app/javascript/controllers/select_menu_controller.js) | Lightweight select alternative |
| `session` | [`session_controller.js`](../../app/javascript/controllers/session_controller.js) | Session/keepalive heartbeat |
| `sidebar` | [`sidebar_controller.js`](../../app/javascript/controllers/sidebar_controller.js) | Hover-driven sidebar expand/collapse |
| `switch-locale` | [`switch_locale_controller.js`](../../app/javascript/controllers/switch_locale_controller.js) | Locale switcher form submission |
| `syntax-highlight` | [`syntax_highlight_controller.js`](../../app/javascript/controllers/syntax_highlight_controller.js) | Syntax highlighter wrapper |
| `tabs` | [`tabs_controller.js`](../../app/javascript/controllers/tabs_controller.js) | Tab group state machine |
| `tags-select` | [`tags_select_controller.js`](../../app/javascript/controllers/tags_select_controller.js) | Tag multi-select combobox |
| `textarea-autogrow` | [`textarea_autogrow_controller.js`](../../app/javascript/controllers/textarea_autogrow_controller.js) | Auto-growing textarea |
| `time-format-component` | [`time_format_component_controller.js`](../../app/javascript/controllers/time_format_component_controller.js) | Relative-time renderer |
| `toast` | [`toast_controller.js`](../../app/javascript/controllers/toast_controller.js) | Stack-managed transient toasts |
| `turbo` | [`turbo_controller.js`](../../app/javascript/controllers/turbo_controller.js) | Global Turbo event hooks |

## Patterns

### Lifecycle and document-level listeners

Turbo replaces the `<body>` on every navigation, so `disconnect()` runs for every controller on every page. Anything registered in `connect()` must be removable in `disconnect()` — especially listeners outside `this.element` (`document`, `window`).

Two failure modes:

1. **Listener leaks.** `document.addEventListener("scroll", () => …)` with an inline arrow function creates a new reference on every `connect()`. After *N* article views you have *N* listeners firing on every scroll. Store the bound handler as an instance property so `disconnect()` can pass the same reference back to `removeEventListener`.
2. **Active timers.** Clear `setTimeout` handles in `disconnect()` so a queued callback cannot fire against a controller whose DOM is gone.

The reference example is [`floating_controller.js`](../../app/javascript/controllers/floating_controller.js):

```javascript
import { Controller } from "@hotwired/stimulus";
import { debounce } from "underscore";

export default class extends Controller {
  static values = {
    showDelay: { type: Number, default: 150 },
    hideDelay: { type: Number, default: 500 },
  };

  connect() {
    this.show = debounce(this.show.bind(this), this.showDelayValue);
    this.hide = this.hide.bind(this);

    this.boundOnScroll = () => {
      this.show();
      clearTimeout(this.hideTimer);
      this.hideTimer = setTimeout(this.hide, this.hideDelayValue);
    };

    this.element.classList.remove("translate-x-24");
    document.addEventListener("scroll", this.boundOnScroll, { passive: true });
  }

  disconnect() {
    if (this.boundOnScroll) {
      document.removeEventListener("scroll", this.boundOnScroll);
    }
    if (this.hideTimer) {
      clearTimeout(this.hideTimer);
    }
  }

  show() {
    this.element.classList.add("translate-y-24");
  }

  hide() {
    this.element.classList.remove("translate-y-24");
  }
}
```

Things to notice in the example: `this.boundOnScroll` is a stored reference (inline lambdas cannot be removed); the scroll listener is `{ passive: true }` so Chrome does not stall paint waiting on a `preventDefault`; `show` is wrapped in `debounce(fn, ms)` once in `connect()` — calling `debounce(classList.add(...), 1000)` would not work because `classList.add(...)` runs eagerly and returns `undefined`; `disconnect()` clears both the document listener and the pending hide timer.

The same lifecycle pattern — store a bound handler, add it in `connect()`, remove it in `disconnect()` — also applies to element-scoped listeners, not only `document`/`window`. See [`prefetch_controller.js`](../../app/javascript/controllers/prefetch_controller.js): `this.boundOnMouseover = debounce(this.prefetch, this.debounceDelayValue)` in `connect()`, with the matching `this.element.removeEventListener("mouseover", this.boundOnMouseover)` in `disconnect()`. Because Turbo replaces the body on every navigation, an inline `mouseover` arrow would leak one listener per visit; storing the bound reference is what makes teardown possible.

### Debouncing DOM writes

Wrap DOM-mutating work in `debounce` so a burst of events collapses into a single write. Reuse `underscore`'s `debounce` (already in the bundle):

```javascript
import { debounce } from "underscore";

connect() {
  this.persist = debounce(this.persist.bind(this), 500);
}

disconnect() {
  // `debounce` returns a function with a `.cancel()` method — flush it
  // so a pending call never fires after the controller is gone.
  this.persist.cancel();
}
```

For observer-style work that does not need DOM writes, prefer `IntersectionObserver` or `MutationObserver` — see [`infinite_scroll_controller.js`](../../app/javascript/controllers/infinite_scroll_controller.js).

The same pattern is applied to a per-element event listener in [`prefetch_controller.js`](../../app/javascript/controllers/prefetch_controller.js), where the `mouseover` handler is `debounce(this.prefetch, this.debounceDelayValue)` so a brief hover collapses into a single prefetch attempt. The debounce delay is exposed as a Stimulus value (`data-prefetch-debounce-delay-value`, default `150` ms) so views can tune it without forking the controller.

### Using `stimulus-use`

[`stimulus-use`](https://github.com/stimulus-use/stimulus-use) mixins add shared lifecycle hooks. Two in use today: `useHover` (`mouseEnter` / `mouseLeave`, [`sidebar_controller.js`](../../app/javascript/controllers/sidebar_controller.js)) and `useTransition` (`enter` / `leave` / `toggle`, [`dropdown_controller.js`](../../app/javascript/controllers/dropdown_controller.js)). Activate them in `connect()`:

```javascript
import { useHover } from "stimulus-use";

connect() {
  useHover(this);
}

mouseEnter() { /* … */ }
mouseLeave() { /* … */ }
```

## Adding a new controller

1. Run `./bin/rails generate stimulus <name>` (or hand-create `app/javascript/controllers/<name>_controller.js` and add `application.register("<name>", <Name>Controller)` to `index.js`).
2. Implement `connect()` and `disconnect()`. Tear down everything you set up — listeners, timers, observers, document-level registrations.
3. For listeners outside `this.element`, store the bound handler on `this` and pass `{ passive: true }` where appropriate.
4. Wrap DOM-write bursts in `debounce(fn, ms)` and `cancel()` it from `disconnect()` if the controller may be torn down before the debounced call fires. When the delay is meant to be tunable from a view, expose it as a Stimulus value (see `prefetch_controller.js`'s `debounceDelay` value, default `150` ms, consumed via `data-prefetch-debounce-delay-value`).
5. Add a row to the catalog above.
6. Run `bun run lint-check` (Prettier) on the touched files before opening a pull request.

## See also

- [Explanation → Architecture](../explanation/architecture.md) — the broader frontend stack (Hotwire, Tailwind, esbuild, Bun)
- [How-to → Set up local development](../how-to/local-development.md) — Bun + esbuild tooling
- [AGENTS.md](../../AGENTS.md) — agent-facing project context and tech-stack table
- [`.cursor/rules/javascript-frontend.mdc`](../../.cursor/rules/javascript-frontend.mdc) — agent-side conventions (Stimulus + esbuild)