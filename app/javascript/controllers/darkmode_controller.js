import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    if (window.matchMedia('(prefers-color-scheme: dark)')?.matches) {
      document
        .querySelector('meta[name="theme-color"]')
        .setAttribute('content', '#18181b');
    }
  }
}
