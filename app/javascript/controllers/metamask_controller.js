import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';
import detectEthereumProvider from '@metamask/detect-provider';
import { ensureEthAccountExist, ERC20ABI, fetchAssetContract } from 'utils';

const provider = await detectEthereumProvider();

export default class extends Controller {
  static targets = ['loginButton'];

  async connect() {
    if (provider !== window.ethereum) return;
    const { account, web3 } = await ensureEthAccountExist();
    this.account = account;
    this.web3 = web3;
  }

  async login(event) {
    event.preventDefault();

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

  async pay(event) {
    event.preventDefault();

    const { assetId, amount, opponentId, memo, traceId, contract } =
      event.params;

    if (!contract) return;
    if (!this.account) return;

    const res = await post('/mvm/extras', {
      body: {
        receivers: [opponentId],
        threshold: 1,
        extra: memo,
      },
    });
    const { extra } = await res.json;
    const assetContractAddress = await fetchAssetContract(assetId);

    let Contract = new this.web3.eth.Contract(ERC20ABI, assetContractAddress);
    let value = parseInt(parseFloat(amount) * 1e8);
    Contract.methods
      .transferWithExtra(contract, value, `0x${extra}`)
      .send({ from: this.account })
      .on('transactionHash', function (hash) {
        console.log(hash);
      });
  }
}
