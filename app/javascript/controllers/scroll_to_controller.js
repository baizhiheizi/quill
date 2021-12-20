import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    offset: Number,
    behavior: String,
  };

  initialize() {
    this.scroll = this.scroll.bind(this);
  }

  connect() {
    this.element.addEventListener('click', this.scroll);
  }

  disconnect() {
    this.element.removeEventListener('click', this.scroll);
  }

  scroll(eventt) {
    event.preventDefault();

    const id = this.element.hash.replace(/^#/, '');
    const target = document.getElementById(id);

    if (!target) {
      console.warn(
        `[stimulus-scroll-to] The element with the id: "${id}" does not exist on the page.`,
      );
      return;
    }

    const elementPosition =
      target.getBoundingClientRect().top + window.pageYOffset;
    const offsetPosition = elementPosition - this.offset;

    window.scrollTo({
      top: offsetPosition,
      behavior: this.behavior,
    });
  }

  get offset() {
    if (this.hasOffsetValue) {
      return this.offsetValue;
    }

    if (this.defaultOptions.offset !== undefined) {
      return this.defaultOptions.offset;
    }

    return 10;
  }

  get behavior() {
    return this.behaviorValue || this.defaultOptions.behavior || 'smooth';
  }

  get defaultOptions() {
    return {};
  }
}
