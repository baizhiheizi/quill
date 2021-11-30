import { Controller } from '@hotwired/stimulus';
import { useTransition } from 'stimulus-use';

export default class extends Controller {
  static targets = ['menu'];

  connect() {
    useTransition(this, {
      element: this.menuTarget,
    });
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
