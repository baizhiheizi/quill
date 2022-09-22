import { Controller } from '@hotwired/stimulus';
import tippy from 'tippy.js';

export default class extends Controller {
  static targets = ['button', 'content'];

  connect() {
    tippy(this.buttonTarget, {
      theme: 'light-border',
      content: this.contentTarget.innerHTML,
      trigger: 'click',
      allowHTML: true,
      interactive: true,
      hideOnClick: true
    });
  }
}
