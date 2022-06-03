import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    this.toastSlot = document.querySelector('#toast-slot');
  }

  show() {}

  loadingTemplate() {
    return ``;
  }
}
