import { Controller } from '@hotwired/stimulus';
import { debounce } from 'underscore';

export default class extends Controller {
  connect() {
    this.listenToScroll();
  }

  listenToScroll() {
    let scrolling;
    document.addEventListener('scroll', () => {
      clearTimeout(scrolling);

      debounce(this.element.classList.add('hidden'), 100);

      scrolling = setTimeout(() => {
        this.element.classList.remove('hidden');
      }, 100);
    });
  }
}
