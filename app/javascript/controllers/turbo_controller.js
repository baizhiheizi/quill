import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';

export default class extends Controller {
  initialize() {
    this.element.setAttribute('data-action', 'click->turbo#click');
  }

  click(event) {
    event.preventDefault();
    this.url = this.element.getAttribute('href');
    get(this.url, {
      responseKind: 'turbo_stream',
    });
  }
}
