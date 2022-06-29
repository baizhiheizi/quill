import { Controller } from '@hotwired/stimulus';
import { useTransition } from 'stimulus-use';

export default class extends Controller {
  static values = {
    delay: Number,
  };

  initialize() {}

  connect() {
    useTransition(this);
    this.enter();
    this.timeout = setTimeout(() => this.hide(), this.delayValue || 3000);
  }

  async hide() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    await this.leave();

    this.element.remove();
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }
}
