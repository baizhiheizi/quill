import { Controller } from '@hotwired/stimulus';
import { debounce } from 'underscore';

export default class extends Controller {
  connect() {
    this.listenToScroll();
  }

  listenToScroll() {
    let scrolling;
    this.element.classList.remove('translate-x-24');
    document.addEventListener('scroll', () => {
      clearTimeout(scrolling);

      debounce(this.element.classList.add('translate-y-24'), 1000);

      scrolling = setTimeout(() => {
        this.element.classList.remove('translate-y-24');
      }, 500);
    });
  }
}
