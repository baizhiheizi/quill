import { Controller } from '@hotwired/stimulus';
import { debounce } from 'underscore';

export default class extends Controller {
  connect() {
    let scrolling;
    document.addEventListener('scroll', () => {
      clearTimeout(scrolling);

      debounce(this.element.classList.add('hidden'), 500);

      scrolling = setTimeout(() => {
        this.element.classList.remove('hidden');
      }, 500);
    });
  }
}
