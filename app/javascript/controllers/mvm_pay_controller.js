import { Controller } from '@hotwired/stimulus';
import { notify, showLoading, hideLoading, initWallet } from '../utils';
import { payWithMVM } from '../utils/pay';

export default class extends Controller {
  static targets = ['metaMaskIcon', 'walletConnectIcon', 'waiting'];

  async initialize() {
    try {
      await initWallet();
    } catch (error) {
      notify(error.message, 'danger');
    }
  }

  metaMaskIconTargetConnected() {
    window.w3 &&
      w3.currentProvider.isMetaMask &&
      this.metaMaskIconTarget.classList.remove('hidden');
  }

  walletConnectIconTargetConnected() {
    window.w3 &&
      w3.currentProvider.wc &&
      this.walletConnectIconTarget.classList.remove('hidden');
  }

  async pay(event) {
    event.preventDefault();

    const { assetId, symbol, amount, opponentId, memo, mixinUuid } =
      event.params;

    this.lockButton();
    try {
      notify(
        `Invoking ${
          w3.currentProvider.isMetaMask
            ? 'MetaMask'
            : w3.currentProvider.wc.peerMeta.name
        } to pay ${amount} ${symbol}`,
        'info',
      );
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
