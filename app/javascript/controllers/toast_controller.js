import { Controller } from '@hotwired/stimulus';
import { useTransition } from 'stimulus-use';

export default class extends Controller {
  connect() {
    this.toastSlot = document.querySelector('#toast-slot');
  }

  show() {}

  loadingTemplate() {
    return ``;
  }
}
