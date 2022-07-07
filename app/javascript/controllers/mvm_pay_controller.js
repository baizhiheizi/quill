import { Controller } from '@hotwired/stimulus';
import {
  notify,
  showLoading,
  hideLoading,
  initMetaMask,
  initWalletConnect,
} from '../utils';
import { payWithMVM } from '../utils/pay';

export default class extends Controller {
  static targets = ['metaMaskIcon', 'walletConnectIcon', 'waiting'];

  initialize() {
    const walletConnect = localStorage.getItem('walletconnect');
    this.walletConnect = walletConnect && JSON.parse(walletConnect);
  }

  metaMaskIconTargetConnected() {
    !this.walletConnect &&
      window.ethereum &&
      ethereum.isMetaMask &&
      this.metaMaskIconTarget.classList.remove('hidden');
  }

  walletConnectIconTargetConnected() {
    this.walletConnect &&
      this.walletConnectIconTarget.classList.remove('hidden');
  }

  async pay(event) {
    event.preventDefault();

    const { assetId, symbol, amount, opponentId, memo, mixinUuid } =
      event.params;

    if (this.walletConnect && this.walletConnect.connected) {
      await initWalletConnect();
    } else if (window.ethereum && ethereum.isConnected()) {
      await initMetaMask();
    } else {
      notify('No wallet connected', 'danger');
      return;
    }

    this.lockButton();
    try {
      notify(
        `Invoking ${
          w3.currentProvider.isMetaMask
            ? 'MetaMask'
            : this.walletConnect.peerMeta.name
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
