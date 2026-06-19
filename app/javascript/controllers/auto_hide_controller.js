import { Controller } from "@hotwired/stimulus";

// Hides the element after `delay` ms. Used by the article editor's "saved"
// checkmark to fade out a few seconds after the save is shown. The handle is
// stored so `disconnect()` can cancel the pending hide (e.g. on a Turbo
// navigation) before the timeout fires against a detached element.
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
    }
  }
}
