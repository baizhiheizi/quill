import { Controller } from '@hotwired/stimulus';
import debounce from 'lodash/debounce';

export default class extends Controller {
  static targets = ['form'];
  static values = {
    delay: Number,
  };

  initialize() {
    this.save = this.save.bind(this);
  }

  connect() {
    if (this.delayValue > 0) {
      this.save = debounce(this.save, this.delayValue);
    }
  }

  save() {
    if (!window._rails_loaded) return;

    this.formTarget.requestSubmit();
  }
}
