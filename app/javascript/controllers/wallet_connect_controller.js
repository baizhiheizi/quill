import { Controller } from '@hotwired/stimulus';
import {
  notify,
  showLoading,
  hideLoading,
  initWalletConnect,
  authorize,
} from '../utils';

export default class extends Controller {
  connect() {}

  async login(event) {
    event.preventDefault();

    await initWalletConnect();

    this.lockButton();
    try {
      await authorize();
    } catch (error) {
      notify(error.message, 'danger');
      this.unlockButton();
    }
  }

  lockButton() {
    this.element.setAttribute('disabled', true);
    showLoading();
  }

  unlockButton() {
    this.element.removeAttribute('disabled');
    hideLoading();
  }
}
