import { Controller } from '@hotwired/stimulus';
import debounce from 'debounce';

export default class extends Controller {
  static targets = ['seachInput', 'currencyOption'];

  initialize() {
    this.search = this.search.bind(this);
  }

  connect() {
    this.search = debounce(this.search, 300);
  }

  search(event) {
    const regex = new RegExp(event.target.value, 'ig');
    this.currencyOptionTargets.forEach((option) => {
      if (regex.test(option.dataset.modalSymbolParam)) {
        option.classList.remove('hidden');
      } else {
        option.classList.add('hidden');
      }
    });
  }
}
