import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    delay: 3000,
  };

  connect() {
    setTimeout(() => this.element.classList.add('hidden'), this.delayValue);
  }
}
