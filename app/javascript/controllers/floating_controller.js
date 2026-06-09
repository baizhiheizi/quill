import { Controller } from "@hotwired/stimulus";
import { debounce } from "underscore";

// Shows a mobile floating action bar at the bottom of the article page as
// the user scrolls down, then hides it after they stop. Implemented as a
// passive document-level scroll listener so the browser can keep scroll
// smooth and so we don't block the main thread with handler work.
//
// Energy notes:
// - Uses `{ passive: true }` so the browser doesn't block paint while
// waiting on this listener (Chrome treats non-passive listeners as a
// scroll-blocking possibility).
// - Wraps the DOM mutation in a debounced function. The previous
// implementation called `debounce(classList.add(...),1000)`, which
// invoked `classList.add` immediately on every scroll event (the
// return value of `classList.add` is undefined, so `debounce` had no
// effect). With the correct wrapping, a single DOM write happens at
// most once per `showDelay` ms regardless of scroll velocity.
// - Stores the bound handler so `disconnect()` can remove the exact
// reference. The previous implementation passed an inline arrow
// function each time `connect()` ran, so the listener was effectively
// un-removable — accumulating one scroll handler per Stimulus
// reconnect (i.e. per Turbo navigation). After N article views, N
// scroll listeners would all fire on every scroll event.
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
