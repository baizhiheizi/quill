import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';
import { notify, showLoading, hideLoading } from '../utils';
import { EthWallet } from '../mvm/eth_wallet';

export default class extends Controller {
  static targets = ['loginButton', 'waiting'];

  async login(event) {
    event.preventDefault();

    const { provier } = event.params;
    window.Wallet = new EthWallet(provier, {
      name: 'Quill',
      logoUrl: `${location.href}/logo.svg`,
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

  async getNounce(account) {
    const res = await post('/nounce', {
      body: {
        public_key: account,
      },
      contentType: 'application/json',
    });

    return await res.json;
  }

  async authorize() {
    if (!window.Wallet) return;

    const nounce = await this.getNounce(Wallet.account);
    const signature = await Wallet.web3.eth.personal.sign(
      JSON.stringify(nounce),
      Wallet.account,
    );

    location.replace(
      `/auth/mvm/callback?signature=${signature}&public_key=${
        Wallet.account
      }&provider=${Wallet.provider}&return_to=${encodeURIComponent(
        location.href,
      )}`,
    );
  }
}
