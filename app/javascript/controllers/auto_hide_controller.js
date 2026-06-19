import { Controller } from "@hotwired/stimulus";

// Hides the element after `delay` ms. Used by the article editor's "saved"
// checkmark to fade out a few seconds after the save is shown.
//
// Energy notes:
// - Stores the timer handle so `disconnect()` can cancel the pending
//   hide if the controller disconnects (e.g. a Turbo navigation)
//   before the timeout fires. Without this, a reconnect cycle can
//   leave the previous callback running against a detached element.
export default class extends Controller {
  static values = {
    delay: 3000,
  };

  connect() {
    this.timer = setTimeout(
      () => this.element.classList.add("hidden"),
      this.delayValue,
    );
  }

  disconnect() {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }
}
