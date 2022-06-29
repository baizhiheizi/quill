import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';
import {
  ensureEthAccountExist,
  ERC20ABI,
  BridgeAddress,
  BridgeABI,
  RegistryContract,
  notify,
  showLoading,
  hideLoading,
} from 'utils';
const XIN_ASSET_ID = 'c94ac88f-4671-3976-b60a-09064f1811e8';

export default class extends Controller {
  static targets = ['loginButton', 'waiting'];

  async connect() {}

  async login(event) {
    event.preventDefault();

    const { account, web3 } = await ensureEthAccountExist();
    this.account = account;
    this.web3 = web3;

    if (!this.account) return;
    await this.requestLogin();
  }

  async requestLogin() {
    const nounce = await this.getNounce();
    const signature = await this.web3.eth.personal.sign(
      JSON.stringify(nounce),
      this.account,
    );

    Turbo.visit(
      `/auth/mvm/callback?signature=${signature}&public_key=${
        this.account
      }&return_to=${encodeURIComponent(location.href)}`,
    );
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

    const { assetId, symbol, amount, opponentId, memo, contract } =
      event.params;

    if (!contract) return;
    if (!this.account) return;

    showLoading();
    const res = await post('/mvm/extras', {
      body: {
        receivers: [opponentId],
        threshold: 1,
        extra: memo,
      },
    });
    const { extra } = await res.json;

    if (assetId === XIN_ASSET_ID) {
      this.payXIN({ symbol, amount, contract, extra });
    } else {
      this.payERC20({ assetId, symbol, amount, contract, extra });
    }
    hideLoading();
  }

  async payERC20(params) {
    const { assetId, symbol, amount, contract, extra } = params;

    const registry = new RegistryContract();
    const assetContractAddress = await registry.fetchAssetContract(assetId);
    if (!assetContractAddress || !parseInt(assetContractAddress)) {
      notify('Desposit some asset first', 'warning');
      return;
    }

    let IERC20 = new this.web3.eth.Contract(ERC20ABI, assetContractAddress);

    let payAmount = parseInt(parseFloat(amount) * 1e8);
    const balance = await IERC20.methods.balanceOf(this.account).call();
    console.log(balance);
    if (balance < payAmount) {
      notify('Insufficient balance', 'warning');
      return;
    }

    IERC20.methods
      .transferWithExtra(contract, payAmount, `0x${extra}`)
      .send({ from: this.account })
      .on('sent', () => {
        notify(`Invoking MetaMask to pay ${amount} ${symbol}`, 'info');
        this.element.setAttribute('disabled', true);
      })
      .on('transactionHash', () => {
        notify('Already paid', 'success');
        this.element.outerHTML = this.waitingTarget.innerHTML;
      })
      .on('error', (error) => {
        this.element.removeAttribute('disabled');
        notify(error.message, 'danger');
      });
  }

  async payXIN(params) {
    const { symbol, amount, contract, extra } = params;

    const BridgeContract = new this.web3.eth.Contract(BridgeABI, BridgeAddress);
    BridgeContract.methods
      .release(contract, `0x${extra}`)
      .send({ from: this.account, value: parseInt(parseFloat(amount) * 1e18) })
      .on('sent', () => {
        notify(`Invoking MetaMask to pay ${amount} ${symbol}`, 'info');
        this.element.setAttribute('disabled', true);
      })
      .on('transactionHash', () => {
        notify('Already paid', 'success');
        this.element.outerHTML = this.waitingTarget.innerHTML;
      })
      .on('error', (error) => {
        this.element.removeAttribute('disabled');
        notify(error.message, 'danger');
      });
  }
}
