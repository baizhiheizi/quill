import { Controller } from '@hotwired/stimulus';
import { useTransition } from 'stimulus-use';

export default class extends Controller {
  static targets = ['modal'];

  connect() {
    useTransition(this, {
      element: this.modalTarget,
    });
    if (this.data.get('initialState') == 'show') {
      this.enter();
    }
  }

  hide() {
    this.leave();
    this.element.remove();
  }

  disconnect() {
    this.leave();
    this.element.remove();
  }
}
