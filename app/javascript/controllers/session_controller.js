import { Controller } from '@hotwired/stimulus';
import { initCoinBase, initMetaMask, initWalletConnect } from '../mvm/wallet';
import { notify } from '../utils';

export default class extends Controller {
  static values = {
    provider: String,
    address: String,
    session: String,
  };

  providerValueChanged() {
    this.initWallet();
  }

  async initWallet() {
    if (!this.providerValue) return;

    switch (this.providerValue) {
      case 'MetaMask':
        await initMetaMask();
        break;
      case 'WalletConnect':
        await initWalletConnect();
        break;
      case 'Coinbase':
        await initCoinBase();
        break;
      default:
        break;
    }

    if (!window.w3) {
      console.warn('Failed to init wallet');
      return;
    }

    w3.provider = this.providerValue;

    w3.currentProvider.on('chainChanged', (chainId) => {
      if (parseInt(w3.currentProvider.chainId) === parseInt(chainId)) return;

      console.warn(`Chain changed to ${chainId}`);
      notify(`Network changed to ${chainId}`);
      Turbo.visit(location.pathname);
    });

    w3.currentProvider.on('accountsChanged', (accounts) => {
      console.warn(`Account changed to ${accounts[0]}`);
      notify('Account changed');

      if (accounts[0].toLowerCase() !== this.addressValue.toLowerCase()) {
        this.destroy();
        Turbo.visit('/logout');
      }
    });

    w3.currentProvider.on('disconnect', () => {
      Turbo.visit('/logout');
    });
  }

  destroy() {
    if (!w3 || !w3.currentProvider || !w3.currentProvider.disconnect) return;

    w3.currentProvider.disconnect();
  }
}
