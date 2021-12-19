import { Controller } from '@hotwired/stimulus';
import { useTransition } from 'stimulus-use';

export default class extends Controller {
  connect() {
    useTransition(this);
    this.enter();
  }

  async hide() {
    await this.leave();
    this.element.remove();
  }
}
