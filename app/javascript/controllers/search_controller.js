import { Controller } from '@hotwired/stimulus';
import lodash from 'lodash';
import { get } from '@rails/request.js';

export default class extends Controller {
  static targets = ['form', 'input', 'clearButton'];

  initialize() {
    this.search = this.search.bind(this);
  }

  connect() {
    this.search = lodash.debounce(this.search, 300);
  }

  submit() {
    const query = this.inputTarget.value;
    this.search(query);
  }

  search(query) {
    if (query) {
      this.showClearButton();
      get(`/search?query=${query}`, {
        contentType: 'application/json',
        responseKind: 'turbo-stream',
      });
    } else {
      this.hideClearButton();
    }
  }

  showClearButton() {
    this.clearButtonTarget.classList.remove('hidden');
  }

  hideClearButton() {
    this.clearButtonTarget.classList.add('hidden');
  }

  clear() {
    this.inputTarget.value = '';
    this.hideClearButton();
  }
}
