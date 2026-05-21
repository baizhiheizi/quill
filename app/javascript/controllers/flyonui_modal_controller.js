import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    backdrop: { type: String, default: 'default' },
  };

  connect() {
    window.HSStaticMethods?.autoInit(['overlay']);

    if (window.HSOverlay) {
      window.HSOverlay.open(this.element);
    } else {
      this.element.classList.remove('hidden');
    }

    if (this.backdropValue === 'static') {
      document.body.style.overflow = 'hidden';
    }
  }

  ok(event) {
    this.dispatch('ok', { detail: event.params, prefix: 'modal-component' });
    this.close();
  }

  cancel(event) {
    this.dispatch('cancel', {
      detail: event.params,
      prefix: 'modal-component',
    });
    this.close();
  }

  close() {
    if (window.HSOverlay) {
      window.HSOverlay.close(this.element);
    } else {
      this.element.classList.add('hidden');
    }

    this.cleanup();
  }

  submitEnd(event) {
    if (this.backdropValue === 'static') return;
    if (event.detail.success) this.close();
  }

  disconnect() {
    this.cleanup();
  }

  cleanup() {
    document.body.style.overflow = '';
    this.element.remove();
  }
}
