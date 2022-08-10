import { Controller } from '@hotwired/stimulus';
import { initCoinBase, initMetaMask, initWalletConnect } from '../mvm/wallet';
import { notify } from '../utils';

export default class extends Controller {
  static values = {
    provider: String,
    address: String,
    session: String,
  };

  async providerValueChanged() {
    if (!this.providerValue) return;

    await this.initWallet();
    if (!w3) return;

    w3.provider = this.providerValue;

    w3.currentProvider.on('chainChanged', (chainId) => {
      console.warn(`Chain changed to ${chainId}`);
      notify(`Network changed to ${chainId}`);
    });

    w3.currentProvider.on('disconnect', () => {
      console.warn('Disconnect');
      Turbo.visit('/logout');
    });
  }

  async addressValueChanged() {
    if (!this.addressValue) return;

    await this.initWallet();
    if (!w3) return;

    w3.currentProvider.on('accountsChanged', (accounts) => {
      notify('Account changed');

      if (accounts[0].toLowerCase() !== this.addressValue.toLowerCase()) {
        this.destroy();
        Turbo.visit('/logout');
      }
    });
  }

  async initWallet() {
    if (!this.providerValue) return;
    if (window.w3) return;

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
    }
  }

  destroy() {
    if (!w3 || !w3.currentProvider || !w3.currentProvider.disconnect) return;

    w3.currentProvider.disconnect();
  }
}
