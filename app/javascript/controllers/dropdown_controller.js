import { Controller } from '@hotwired/stimulus';
import { useTransition } from 'stimulus-use';

export default class extends Controller {
  static targets = ['menu'];
  static values = { initialState: String };

  connect() {
    useTransition(this, {
      element: this.menuTarget,
    });
    if (this.initialStateValue) {
      this.enter();
    }
  }

  toggle() {
    this.toggleTransition();
  }

  hide(event) {
    if (
      !this.element.contains(event.target) &&
      !this.menuTarget.classList.contains('hidden')
    ) {
      this.leave();
    }
  }
}
