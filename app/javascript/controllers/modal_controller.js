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

  ok(event) {
    this.dispatch("ok", { detail: { identifier: event.params.identifier }});
    this.hide();
  }

  cancel(event) {
    this.dispatch("cancel", { detail: { identifier: event.params.identifier }});
    this.hide();
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
