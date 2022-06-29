import { Controller } from '@hotwired/stimulus';
import hljs from 'highlight.js';

export default class extends Controller {
  connect() {
    this.element.querySelectorAll('pre code').forEach((el) => {
      hljs.highlightElement(el);
    });
  }
}
