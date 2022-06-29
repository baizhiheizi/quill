import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';
import detectEthereumProvider from '@metamask/detect-provider';
import {
  ensureEthAccountExist,
  ERC20ABI,
  BridgeAddress,
  BridgeABI,
  RegistryContract,
  notify,
  showLoading,
  hideLoading,
} from '../utils';
import BigNumber from 'bignumber.js';
const XIN_ASSET_ID = 'c94ac88f-4671-3976-b60a-09064f1811e8';

export default class extends Controller {
  static targets = ['loginButton', 'waiting'];

  async login(event) {
    const provider = await detectEthereumProvider();
    if (provider !== window.ethereum) return;

    event.preventDefault();
    const { account, web3 } = await ensureEthAccountExist();
    if (!account) return;

    this.lockButton();
    try {
      const nounce = await this.getNounce(account);
      const signature = await web3.eth.personal.sign(
        JSON.stringify(nounce),
        account,
      );

      Turbo.visit(
        `/auth/mvm/callback?signature=${signature}&public_key=${account}&return_to=${encodeURIComponent(
          location.href,
        )}`,
      );
    } catch (error) {
      notify(error.message, 'danger');
      this.unlockButton();
    }
  }

  async pay(event) {
    event.preventDefault();

    try {
      const { assetId, symbol, amount, opponentId, memo, contract } =
        event.params;
      if (!contract) return;

      const { extra } = await this.fetchExtra(opponentId, memo);

      if (assetId === XIN_ASSET_ID) {
        await this.payXIN({ symbol, amount, contract, extra });
      } else {
        await this.payERC20({ assetId, symbol, amount, contract, extra });
      }
    } catch (error) {
      notify(error.message, 'danger');
      this.unlockButton();
    }
  }

  async payERC20(params) {
    const { assetId, symbol, amount, contract, extra } = params;
    const { account, web3 } = await ensureEthAccountExist();

    this.lockButton();

    const registry = new RegistryContract();
    const assetContractAddress = await registry.fetchAssetContract(assetId);
    if (!assetContractAddress || !parseInt(assetContractAddress)) {
      notify('Desposit some asset first', 'warning');
      this.unlockButton();
      return;
    }

    let IERC20 = new web3.eth.Contract(ERC20ABI, assetContractAddress);

    let payAmount = BigNumber(amount).multipliedBy(BigNumber(1e8));

    const balance = await IERC20.methods.balanceOf(account).call();
    if (BigNumber(balance).isLessThan(payAmount)) {
      notify('Insufficient balance', 'warning');
      this.unlockButton();
      return;
    }

    IERC20.methods
      .transferWithExtra(contract, payAmount.toString(), `0x${extra}`)
      .send({ from: account })
      .on('sent', () => {
        notify(`Invoking MetaMask to pay ${amount} ${symbol}`, 'info');
      })
      .on('transactionHash', () => {
        this.unlockButton();
        notify('Successfully paid', 'success');
        this.element.outerHTML = this.waitingTarget.innerHTML;
      })
      .on('error', (error) => {
        this.unlockButton();
        notify(error.message, 'danger');
      });
  }

  async payXIN(params) {
    const { symbol, amount, contract, extra } = params;
    const { account, web3 } = await ensureEthAccountExist();
    const BridgeContract = new web3.eth.Contract(BridgeABI, BridgeAddress);

    this.lockButton();

    const payAmount = BigNumber(amount).multipliedBy(BigNumber(1e18));
    BridgeContract.methods
      .release(contract, `0x${extra}`)
      .send({ from: account, value: payAmount.toString() })
      .on('sent', () => {
        notify(`Invoking MetaMask to pay ${amount} ${symbol}`, 'info');
      })
      .on('transactionHash', () => {
        notify('Successfully paid', 'success');
        this.unlockButton();
        this.element.outerHTML = this.waitingTarget.innerHTML;
      })
      .on('error', (error) => {
        this.unlockButton();
        notify(error.message, 'danger');
      });
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

  async fetchExtra(opponentId, memo) {
    const res = await post('/mvm/extras', {
      body: {
        receivers: [opponentId],
        threshold: 1,
        extra: memo,
      },
    });
    return await res.json;
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
