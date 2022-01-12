import { Controller } from '@hotwired/stimulus';
import { useHover } from 'stimulus-use';

export default class extends Controller {
  static values = {
    openClass: Array,
    collapseClass: Array,
  };
  static targets = ['sidebar', 'openButton', 'collapseButton'];

  connect() {
    useHover(this);
  }

  // mouseEnter() {
  //   this.open();
  // }
  //
  // mouseLeave() {
  //   this.collapse();
  // }

  collapse() {
    this.sidebarTarget.classList.add(...this.collapseClassValue);
    this.sidebarTarget.classList.remove(...this.openClassValue);
    this.openButtonTarget.classList.remove('hidden');
    this.collapseButtonTarget.classList.add('hidden');
  }

  open() {
    this.sidebarTarget.classList.add(...this.openClassValue);
    this.sidebarTarget.classList.remove(...this.collapseClassValue);
    this.openButtonTarget.classList.add('hidden');
    this.collapseButtonTarget.classList.remove('hidden');
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.collapse();
    }
  }
}
