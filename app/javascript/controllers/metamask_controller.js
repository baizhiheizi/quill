import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';
import detectEthereumProvider from '@metamask/detect-provider';
import Web3 from 'web3';

const provider = await detectEthereumProvider();
const MVM_CHAIN_ID = '0x120c7';

export default class extends Controller {
  static targets = ['loginButton'];

  connect() {}

  async login(event) {
    if (provider !== window.ethereum) return;
    event.preventDefault();

    await this.ensureEthAccountExist();
    if (!this.account) return;

    await this.requestLogin();
  }

  async requestLogin() {
    const nounce = await this.getNounce();
    const signature = await this.web3.eth.personal.sign(
      JSON.stringify(nounce),
      this.account,
    );

    post('/auth/mvm/callback', {
      body: {
        signature,
        public_key: this.account,
        return_to: location.href,
      },
      contentType: 'application/json',
    }).then(() => {
      Turbo.visit(location.pathname);
    });
  }

  async getNounce() {
    const res = await post('/nounce', {
      body: {
        public_key: this.account,
      },
      contentType: 'application/json',
    });

    return await res.json;
  }

  async ensureEthAccountExist() {
    await this.addMvmChain();
    if (ethereum.chainId !== MVM_CHAIN_ID) return;

    this.web3 = new Web3(ethereum);
    const accounts = await this.web3.eth.getAccounts();
    this.account = accounts[0];
  }

  async addMvmChain() {
    ethereum.request({
      method: 'wallet_addEthereumChain',
      params: [
        {
          chainId: MVM_CHAIN_ID,
          chainName: 'Mixin Virtual Machine',
          nativeCurrency: {
            name: 'Mixin',
            symbol: 'XIN',
            decimals: 18,
          },
          rpcUrls: ['https://geth.mvm.dev'],
          blockExplorerUrls: ['https://scan.mvm.dev/'],
        },
      ],
    });
  }

  pay(event) {
    event.preventDefault();
  }
}
