import { Controller } from '@hotwired/stimulus';
import {
  notify,
  showLoading,
  hideLoading,
  initWalletConnect,
  authorize,
  payWithMVM,
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

  async pay(event) {
    event.preventDefault();

    const { assetId, symbol, amount, opponentId, memo, mixinUuid } =
      event.params;

    await initWalletConnect();
    this.lockButton();
    try {
      notify(`Invoking WalletConnect to pay ${amount} ${symbol}`, 'info');
      await payWithMVM(
        { assetId, symbol, amount, opponentId, memo, mixinUuid },
        () => {
          notify('Successfully paid', 'success');
          this.unlockButton();
          this.element.outerHTML = this.waitingTarget.innerHTML;
        },
        (error) => {
          notify(error.message, 'danger');
          this.unlockButton();
        },
      );
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
