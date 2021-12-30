import { Controller } from '@hotwired/stimulus';
import * as hljs from 'highlight.js';

export default class extends Controller {
  connect() {
    this.element.querySelectorAll('pre code').forEach((el) => {
      hljs.highlightElement(el);
    });
  }
}
