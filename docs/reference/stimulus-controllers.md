# Stimulus controllers reference

> **30-second summary:** Quill's frontend is wired by [Stimulus](https://stimulus.hotwired.dev/) controllers in [`app/javascript/controllers/`](../../app/javascript/controllers/). Each `*_controller.js` exports a default class for one behaviour; the manifest in [`index.js`](../../app/javascript/controllers/index.js) maps `data-controller="…"` to those classes. Listeners attached outside `this.element` **must** be removable from `disconnect()` so Turbo navigations do not leak handlers.

## Conventions

- **One controller per file** in [`app/javascript/controllers/`](../../app/javascript/controllers/), named `<snake_case>_controller.js`.
- **Identifier mapping** lives in `index.js`: `application.register("floating", FloatingController)` binds `data-controller="floating"`. Regenerate after add/rename with `./bin/rails stimulus:manifest:update`.
- **Lifecycle:** anything registered in `connect()` (observers, intervals, document-level listeners) **must** be torn down in `disconnect()`. Store bound handlers as instance properties (`this.boundOnScroll = …`) — inline arrow functions cannot be removed.
- **Values/targets:** declare `static values` and `static targets`; consume via `this.<name>Value` and `this.has<Name>Target` / `this.<name>Target`.
- **Reuse utilities** in [`app/javascript/utils/`](../../app/javascript/utils/) (`toast`, `notify`, `uploader`) and [`stimulus-use`](https://github.com/stimulus-use/stimulus-use) mixins (`useHover`, `useTransition`).

## Catalog

Every controller registered in `app/javascript/controllers/index.js`, with its source file and a one-line purpose. Read the source for full behaviour. All file paths are under `app/javascript/controllers/`.

| Identifier | File | Purpose |
|------------|------|---------|
| `article-form` | `article_form_controller.js` | Article drafting form (markdown editor + price/asset fields) |
| `auto-hide` | `auto_hide_controller.js` | Hides an element after a configurable delay |
| `clipboard` | `clipboard_controller.js` | Copies a target value to the clipboard |
| `collections-form-component` | `collections_form_component_controller.js` | Author-side collection editing UI |
| `comment-form` | `comment_form_controller.js` | Comment composer (inline validation, optimistic render) |
| `darkmode` | `darkmode_controller.js` | Theme toggle persisted to local storage |
| `dropdown` | `dropdown_controller.js` | Open/close menu with enter/leave transitions |
| `eth-wallet` | `eth_wallet_controller.js` | Ethereum (MVM) wallet glue for EIP-1193 providers |
| `fennec` | `fennec_controller.js` | FenneC wallet integration |
| `flash` | `flash_controller.js` | Dismissible flash banners |
| `floating` | `floating_controller.js` | Mobile floating action bar that shows on scroll |
| `flyonui-dropdown` | `flyonui_dropdown_controller.js` | FlyonUI-themed dropdown wrapper |
| `hljs` | `hljs_controller.js` | Highlight.js runner triggered on visible code blocks |
| `infinite-scroll` | `infinite_scroll_controller.js` | Paginates via `IntersectionObserver` |
| `load-more` | `load_more_controller.js` | Click-to-load pagination button |
| `login` | `login_controller.js` | Login form state (provider switching) |
| `modal-component` | `flyonui_modal_controller.js` | FlyonUI-themed modal wrapper (manifest name is `modal-component`, not `flyonui-modal`). |
| `mvm-deposit` | `mvm_deposit_controller.js` | MVM deposit flow state |
| `mvm-pay-button-component` | `mvm_pay_button_component_controller.js` | MVM "pay" button subcomponent |
| `nested-form` | `nested_form_controller.js` | Add/remove nested form rows |
| `photoswipe` | `photoswipe_controller.js` | PhotoSwipe gallery wiring |
| `pre-orders-form-component` | `pre_orders_form_component_controller.js` | Pre-order authoring form |
| `pre-orders-pay-button-component` | `pre_orders_pay_button_component_controller.js` | Generic "pay" button inside pre-order form |
| `pre-orders-payment-component` | `pre_orders_payment_component_controller.js` | Pre-order payment summary panel |
| `pre-orders-state-component` | `pre_orders_state_component_controller.js` | Pre-order status pill |
| `prefetch` | `prefetch_controller.js` | Hover-driven Turbo prefetch. Values: `debounce-delay` (ms, default `150`). |
| `preview-upload` | `preview_upload_controller.js` | Local image preview before upload |
| `qrcode-component` | `qrcode_component_controller.js` | Renders QR codes for deposit addresses |
| `references-select` | `references_select_controller.js` | Cross-article reference picker |
| `search` | `search_controller.js` | Debounced article search box |
| `select-currency` | `select_currency_controller.js` | Currency picker for pre-orders |
| `session` | `session_controller.js` | Session/keepalive heartbeat |
| `sidebar` | `sidebar_controller.js` | Hover-driven sidebar expand/collapse |
| `syntax-highlight` | `syntax_highlight_controller.js` | Syntax highlighter wrapper |
| `tabs` | `tabs_controller.js` | Tab group state machine |
| `tags-select` | `tags_select_controller.js` | Tag multi-select combobox |
| `time-format-component` | `time_format_component_controller.js` | Relative-time renderer |
| `turbo` | `turbo_controller.js` | Global Turbo event hooks |

## Patterns

### Lifecycle and document-level listeners

Turbo replaces the `<body>` on every navigation, so `disconnect()` runs for every controller on every page. Anything registered in `connect()` must be removable in `disconnect()` — especially listeners outside `this.element`. Two failure modes follow:

1. **Listener leaks.** `document.addEventListener("scroll", () => …)` with an inline arrow function creates a new reference on every `connect()`. After *N* article views you have *N* listeners firing on every scroll. Store the bound handler as an instance property so `disconnect()` can pass the same reference to `removeEventListener`.
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

Things to notice: `this.boundOnScroll` is a stored reference (inline lambdas cannot be removed); the scroll listener uses `{ passive: true }` so Chrome does not stall paint waiting on a `preventDefault`; `show` is wrapped in `debounce(fn, ms)` once in `connect()` — passing `classList.add(...)` directly fails because it runs eagerly and returns `undefined`; `disconnect()` clears both the document listener and the pending hide timer. The same pattern applies to element-scoped listeners — see [`prefetch_controller.js`](../../app/javascript/controllers/prefetch_controller.js).

### Observer teardown

`IntersectionObserver` and `MutationObserver` leak the same way as event listeners: the observer holds a closure over the controller, and if `disconnect()` cannot reach it, the closure survives every Turbo navigation. Store the observer as an instance property and call `.disconnect()` on it from `disconnect()`.

The reference example is [`infinite_scroll_controller.js`](../../app/javascript/controllers/infinite_scroll_controller.js):

```javascript
import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";

export default class extends Controller {
  static targets = ["scrollArea", "pagination"];

  connect() {
    this.loading = false;
    this.lastFetchedHref = null;
    this.createObserver();
  }

  createObserver() {
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersect(entries),
      { threshold: [0, 1.0] },
    );
    if (this.hasScrollAreaTarget) {
      this.observer.observe(this.scrollAreaTarget);
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
      this.observer = null;
    }
  }

  handleIntersect(entries) {
    const visible = entries.some((entry) => entry.isIntersecting);
    if (visible) {
      this.loadMore();
    }
  }

  async loadMore() {
    if (this.loading) return;

    const next = this.paginationTarget.querySelector("a");
    if (!next || !next.href) return;

    if (this.lastFetchedHref === next.href) return;

    this.loading = true;
    this.lastFetchedHref = next.href;
    try {
      await get(next.href, {
        contentType: "application/json",
        responseKind: "turbo-stream",
      });
    } finally {
      this.loading = false;
    }
  }
}
```

Things to notice: `this.observer` is stored on the instance — a local `const observer = new IntersectionObserver(...)` would be unreachable from `disconnect()` and leak the observer for the lifetime of the page; the observer is only created when `hasScrollAreaTarget` is true so a partial that lacks the target still tears down cleanly. `IntersectionObserver` callbacks fire repeatedly while the trigger stays in view, so the example dedups fetches in `loadMore()` with `this.loading` (overlapping fetches) and `this.lastFetchedHref` (repeated viewport hits).

### Debouncing DOM writes

Wrap DOM-mutating work in `debounce` (use `underscore`'s, already in the bundle) so a burst of events collapses into a single write:

```javascript
import { debounce } from "underscore";

connect() {
  this.persist = debounce(this.persist.bind(this), 500);
}

disconnect() {
  // cancel pending debounced calls so they don't fire after teardown
  this.persist.cancel();
}
```

For observer-style work that does not need DOM writes, prefer `IntersectionObserver` or `MutationObserver` — see the example above.

### Using `stimulus-use`

[`stimulus-use`](https://github.com/stimulus-use/stimulus-use) mixins add shared lifecycle hooks. Two in use today: `useHover` (`mouseEnter` / `mouseLeave`, [`sidebar_controller.js`](../../app/javascript/controllers/sidebar_controller.js)) and `useTransition` (`enter` / `leave` / `toggle`, [`dropdown_controller.js`](../../app/javascript/controllers/dropdown_controller.js)):

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
2. Implement `connect()` and `disconnect()`. Tear down everything — listeners, timers, observers, document-level registrations — and follow the patterns above for each one.
3. For listeners outside `this.element`, store the bound handler on `this` and pass `{ passive: true }` where appropriate.
4. Wrap DOM-write bursts in `debounce(fn, ms)` and `cancel()` it from `disconnect()`; expose the delay as a Stimulus value when views need to tune it.
5. Add a row to the catalog above.
6. Run `bun run lint-check` (Prettier) on the touched files before opening a pull request.

## See also

- [Explanation → Architecture](../explanation/architecture.md) — Hotwire, Tailwind, esbuild, Bun
- [How-to → Set up local development](../how-to/local-development.md) — Bun + esbuild tooling
- [AGENTS.md](../../AGENTS.md) — agent-facing project context