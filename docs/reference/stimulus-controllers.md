# Stimulus controllers reference

> **30-second summary:** [Stimulus](https://stimulus.hotwired.dev/) controllers in [`app/javascript/controllers/`](../../app/javascript/controllers/) wire Quill's frontend. Each `*_controller.js` exports one class, registered in [`index.js`](../../app/javascript/controllers/index.js) via `data-controller="…"`. Listeners outside `this.element` must be removable from `disconnect()` so Turbo doesn't leak them across navigations.

## Conventions

- **One controller per file** in [`app/javascript/controllers/`](../../app/javascript/controllers/), named `<snake_case>_controller.js`.
- **Identifier mapping** lives in `index.js` — `application.register("floating", FloatingController)` binds `data-controller="floating"`. Regenerate after add/rename with `./bin/rails stimulus:manifest:update`.
- **Lifecycle:** anything registered in `connect()` **must** be torn down in `disconnect()`. Store bound handlers on the instance (`this.boundOnScroll = …`) — inline arrow functions cannot be removed.
- **Values/targets:** declare `static values` and `static targets`; consume via `this.<name>Value` and `this.has<Name>Target` / `this.<name>Target`.
- **Reuse utilities** in [`app/javascript/utils/`](../../app/javascript/utils/) (`toast`, `notify`, `uploader`) and [`stimulus-use`](https://github.com/stimulus-use/stimulus-use) mixins.

## Catalog

Every controller in `app/javascript/controllers/index.js`, with its source file and a one-line purpose. Paths are under `app/javascript/controllers/`.

| Identifier | File | Purpose |
|------------|------|---------|
| `article-form` | `article_form_controller.js` | Article drafting form (markdown editor + price/asset fields) |
| `auto-hide` | `auto_hide_controller.js` | Hides an element after a configurable delay |
| `clipboard` | `clipboard_controller.js` | Copies a target value to the clipboard |
| `collections-form-component` | `collections_form_component_controller.js` | Author-side collection editing UI |
| `comment-form` | `comment_form_controller.js` | Comment composer (inline validation, optimistic render) |
| `darkmode` | `darkmode_controller.js` | Theme toggle persisted to local storage |
| `dropdown` | `dropdown_controller.js` | Open/close menu with transitions |
| `fennec` | `fennec_controller.js` | FenneC wallet integration |
| `flash` | `flash_controller.js` | Dismissible flash banners |
| `floating` | `floating_controller.js` | Floating action bar shown on scroll |
| `flyonui-dropdown` | `flyonui_dropdown_controller.js` | FlyonUI-themed dropdown wrapper |
| `hljs` | `hljs_controller.js` | Highlight.js runner on visible code blocks |
| `infinite-scroll` | `infinite_scroll_controller.js` | Paginates via `IntersectionObserver` |
| `load-more` | `load_more_controller.js` | Click-to-load pagination button |
| `modal-component` | `flyonui_modal_controller.js` | FlyonUI-themed modal wrapper (manifest name is `modal-component`, not `flyonui-modal`). |
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

Turbo replaces `<body>` on every navigation, so `disconnect()` runs for every controller. Anything registered in `connect()` must be removable in `disconnect()` — especially listeners outside `this.element`:

1. **Listener leaks:** `document.addEventListener("scroll", () => …)` creates a new reference on every `connect()`, so `removeEventListener` can't reach it. Store the bound handler as an instance property.
2. **Active timers:** clear `setTimeout` handles in `disconnect()` so a queued callback can't fire against a torn-down controller.

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

Key details: `boundOnScroll` is stored on the instance so `removeEventListener` can reach it. `{ passive: true }` keeps Chrome from stalling paint waiting on `preventDefault`. `show` is debounced in `connect()` since `classList.add(...)` runs eagerly. `disconnect()` clears the listener and pending `hideTimer`. Element-scoped listeners follow the same pattern ([prefetch_controller.js](../../app/javascript/controllers/prefetch_controller.js)).

### Observer teardown

`IntersectionObserver` and `MutationObserver` leak like event listeners if `disconnect()` can't reach the closure. Store the observer as an instance property and call `.disconnect()` on it from `disconnect()`.

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
    if (entries.some((entry) => entry.isIntersecting)) this.loadMore();
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

Key details: `observer` is stored on the instance (a local `const` would leak for the page's lifetime). The observer is only created when `hasScrollAreaTarget` is true. `loadMore()` dedups overlapping fetches (`this.loading`) and repeated viewport hits (`this.lastFetchedHref`).

### Debouncing DOM writes

Wrap DOM-mutating work in `debounce` (`underscore`, already in the bundle) so bursts collapse into one write:

```javascript
import { debounce } from "underscore";

connect() {
  this.persist = debounce(this.persist.bind(this), 500);
}

disconnect() {
  // cancel pending calls so they don't fire after teardown
  this.persist.cancel();
}
```

For observer-style work that does not need DOM writes, prefer `IntersectionObserver` or `MutationObserver` — see the example above.

### Using `stimulus-use`

[`stimulus-use`](https://github.com/stimulus-use/stimulus-use) mixins add shared lifecycle hooks. Two in use: `useHover` ([`sidebar_controller.js`](../../app/javascript/controllers/sidebar_controller.js)) and `useTransition` ([`dropdown_controller.js`](../../app/javascript/controllers/dropdown_controller.js)):

```javascript
import { useHover } from "stimulus-use";

connect() {
  useHover(this);  // adds mouseEnter() / mouseLeave()
}
```

## Adding a new controller

1. Run `./bin/rails generate stimulus <name>` (or hand-create the file and register it in `index.js`).
2. Implement `connect()` and `disconnect()`, tearing down everything registered in `connect()` per the patterns above.
3. Add a row to the catalog above.
4. Run `bun run lint-check` on the touched files before opening a pull request.

## See also

- [Explanation → Architecture](../explanation/architecture.md)
- [How-to → Set up local development](../how-to/local-development.md)
- [AGENTS.md](../../AGENTS.md)