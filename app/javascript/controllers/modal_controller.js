import { Controller } from '@hotwired/stimulus';
import { useTransition } from 'stimulus-use';

export default class extends Controller {
  static targets = ['modal'];

  connect() {
    useTransition(this, {
      element: this.modalTarget,
    });
    if (this.data.get('initialState') == 'show') {
      this.show();
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

  lockBodyScroll() {
    document.body.style.overflow = 'hidden';
  }

  unLockBodyScroll() {
    document.body.style.overflow = '';
  }

  show() {
    this.enter();
    this.lockBodyScroll();
  }

  hide() {
    this.unLockBodyScroll();
    this.leave();
    this.element.remove();
  }

  disconnect() {
    this.unLockBodyScroll();
    this.leave();
    this.element.remove();
  }
}
