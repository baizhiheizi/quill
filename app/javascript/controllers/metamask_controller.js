import { Controller } from '@hotwired/stimulus';
import { initMetaMask } from '../mvm/wallet';
import { authorize } from '../mvm/auth';
import { notify, showLoading, hideLoading } from '../utils';

export default class extends Controller {
  static targets = ['loginButton', 'waiting'];

  connect() {}

  async login(event) {
    event.preventDefault();

    await initMetaMask();
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
