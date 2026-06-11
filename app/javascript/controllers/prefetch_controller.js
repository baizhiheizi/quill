import { Controller } from "@hotwired/stimulus";
import { debounce } from "underscore";

// Prefetches a link's target document so the next navigation is instant.
//
// Energy notes:
// - `mouseover` fires per mouse movement, not just per link visit. The
//   previous handler called `this.prefetch()` directly and used an inline
//   arrow function as the listener. That had two efficiency problems:
//   1. A brief hover that produced several `mouseover` events would
//      run the full prefetch path (including the `navigator.connection`
//      check and the `document.head.querySelector` dedup) once per event.
//   2. The inline arrow function could not be removed in `disconnect()`,
//      so every Stimulus reconnect (one per Turbo navigation) added
//      another mouseover listener that was never removed. After N
//      navigations a single link could be running N prefetch attempts
//      per mouse movement.
// - The fix debounces the prefetch call (collapses bursts into a
//   single attempt) and stores a bound handler reference so
//   `disconnect()` can actually remove it.
export default class extends Controller {
  static values = {
    debounceDelay: { type: Number, default: 150 },
  };

  initialize() {
    this.prefetch = this.prefetch.bind(this);
  }

  connect() {
    if (!this.hasPrefetch) return;

    this.boundOnMouseover = debounce(this.prefetch, this.debounceDelayValue);
    this.element.addEventListener("mouseover", this.boundOnMouseover);
  }

  disconnect() {
    if (this.boundOnMouseover) {
      this.element.removeEventListener("mouseover", this.boundOnMouseover);
      this.boundOnMouseover = null;
    }
  }

  prefetch() {
    const connection = navigator.connection;

    if (connection) {
      // Don't prefetch if using 2G or if Save-Data is enabled.
      if (connection.saveData) {
        console.warn(
          "[stimulus-prefetch] Cannot prefetch, Save-Data is enabled.",
        );
        return;
      }

      if (/2g/.test(connection.effectiveType)) {
        console.warn(
          "[stimulus-prefetch] Cannot prefetch, network conditions are poor.",
        );
        return;
      }
    }
    if (document.head.querySelector(`link[href="${this.element.href}"]`)) {
      return;
    }

    const link = document.createElement("link");
    link.rel = "prefetch";
    link.href = this.element.href;
    link.as = "document";

    document.head.appendChild(link);
  }

  get hasPrefetch() {
    const link = document.createElement("link");

    return (
      link.relList && link.relList.supports && link.relList.supports("prefetch")
    );
  }
}
