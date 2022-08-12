import { Controller } from '@hotwired/stimulus';
import { EthWallet } from '../mvm/eth_wallet';
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
    if (!window.Wallet) return;

    Wallet.web3.currentProvider.on('chainChanged', (chainId) => {
      console.warn(`Chain changed to ${chainId}`);
      notify(`Network changed to ${chainId}`);
    });

    Wallet.web3.currentProvider.on('disconnect', () => {
      if (Wallet.provider === 'MetaMask') return;

      console.warn('Disconnect');
      Turbo.visit('/logout');
    });
  }

  async addressValueChanged() {
    if (!this.addressValue) return;

    await this.initWallet();
    if (!window.Wallet) return;

    Wallet.web3.currentProvider.on('accountsChanged', (accounts) => {
      notify('Account changed');

      if (accounts[0].toLowerCase() !== this.addressValue.toLowerCase()) {
        this.destroy();
        Turbo.visit('/logout');
      }
    });
  }

  async initWallet() {
    if (!this.providerValue) return;
    if (window.Wallet) return;

    window.Wallet = new EthWallet(this.providerValue, {
      name: 'Quill',
      logoUrl: `${location.host}/logo.svg`,
    });
    await Wallet.init();

    if (!window.Wallet) {
      console.warn('Failed to init wallet');
    }
  }

  destroy() {
    if (
      !window.Wallet ||
      !window.Wallet.web3 ||
      !window.Wallet.web3.currentProvider ||
      !window.Wallet.web3.currentProvider.disconnect
    )
      return;

    Wallet.web3.currentProvider.disconnect();
  }
}
