import { Controller } from '@hotwired/stimulus';
import hljs from 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.5.1/build/es/highlight.min.js';

export default class extends Controller {
  connect() {
    this.element.querySelectorAll('pre code').forEach((el) => {
      hljs.highlightElement(el);
    });
  }
}
