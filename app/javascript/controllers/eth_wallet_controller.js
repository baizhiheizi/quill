import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';
import { notify, showLoading, hideLoading } from '../utils';
import { EthWallet } from '../mvm/eth_wallet';
import { WALLET_CONNECT_PROJECT_ID } from '../mvm/constants';

export default class extends Controller {
  static targets = ['loginButton', 'waiting'];

  async login(event) {
    event.preventDefault();

    const { provier } = event.params;
    window.Wallet = new EthWallet(provier, {
      name: 'Quill',
      logoUrl: `${location.href}/logo.svg`,
      wcProjectId: WALLET_CONNECT_PROJECT_ID,
    });
    await Wallet.init();
    this.lockButton();

    try {
      await this.authorize();
    } catch (error) {
      notify(error.message, 'danger');
    }
    this.unlockButton();
  }

  lockButton() {
    this.element.setAttribute('disabled', true);
    showLoading();
  }

  unlockButton() {
    this.element.removeAttribute('disabled');
    hideLoading();
  }

  async getNonce(address) {
    if (!address) return;

    const res = await post('/nonce', {
      body: {
        address,
      },
      contentType: 'application/json',
    });

    return await res.json;
  }

  async authorize() {
    if (!window.Wallet) return;
    if (!Wallet.account) return;

    const nonce = await this.getNonce(Wallet.account);
    const signature = await Wallet.web3.eth.personal.sign(
      JSON.stringify(nonce),
      Wallet.account,
      ""
    );

    location.replace(
      `/auth/mvm/callback?signature=${signature}&address=${
        Wallet.account
      }&provider=${Wallet.provider}&return_to=${encodeURIComponent(
        location.href,
      )}`,
    );
  }
}
