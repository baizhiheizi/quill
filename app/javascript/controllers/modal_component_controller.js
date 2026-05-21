import { Controller } from '@hotwired/stimulus';
import { useTransition } from 'stimulus-use';

export default class extends Controller {
  static values = {
    backdrop: 'default',
    initialState: 'show',
  };
  static targets = ['wrapper', 'backdrop', 'modal', 'title', 'content'];

  connect() {
    useTransition(this, {
      element: this.modalTarget,
    });
    if (this.initialStateValue === 'show') {
      this.show();
    }
  }

  ok(event) {
    this.dispatch('ok', { detail: event.params });
    this.hide();
  }

  cancel(event) {
    this.dispatch('cancel', {
      detail: event.params,
    });
    this.hide();
  }

  lockBodyScroll() {
    document.body.style.overflow = 'hidden';
  }

  unLockBodyScroll() {
    document.body.style.overflow = '';
  }

  backdropClicked() {
    if (this.backdropValue === 'static') return;

    this.hide();
  }

  show() {
    this.enter();
    if (this.backdropValue === 'static') {
      this.lockBodyScroll();
    }
  }

  hide() {
    this.unLockBodyScroll();
    this.leave();
    this.element.remove();
  }

  submitEnd(event) {
    if (this.backdropValue === 'static') return;

    if (event.detail.success) {
      this.hide();
    }
  }

  disconnect() {
    this.unLockBodyScroll();
    this.leave();
    this.element.remove();
  }
}
