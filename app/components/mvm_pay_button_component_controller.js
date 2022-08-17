import { Controller } from '@hotwired/stimulus';
import { notify, showLoading, hideLoading } from '../javascript/utils';

export default class extends Controller {
  static targets = [
    'button',
    'metaMaskIcon',
    'walletConnectIcon',
    'coinbaseIcon',
    'wait',
    'finish',
    'scanTransactionLink',
    'balance',
    'balanceValue',
    'balanceLink',
    'mvmTips',
  ];

  static values = {
    assetId: String,
    assetSymbol: String,
    afterSubmitAction: String,
  };

  connect() {
    this.checkMVM();
  }

  async checkMVM() {
    await Wallet.switchToMVM();

    if (!Wallet.isCurrentNetworkMvm()) {
      let input = this.buttonTarget.querySelector('button');
      if (!input) return;

      this.mvmTipsTarget.classList.remove('hidden');
      input.classList.remove(
        'bg-primary',
        'text-white',
        'hover:font-black',
        'cursor-pointer',
      );
      input.classList.add('bg-zinc-300', 'opacity-50');
      input.disabled = true;
    } else {
      this.balanceTarget.classList.remove('hidden');
    }
  }

  async assetIdValueChanged() {
    if (!this.assetIdValue) return;
    if (!Wallet.isCurrentNetworkMvm()) return;

    const account = await Wallet.account;
    if (!account) return;

    const balance = await Wallet.balanceOf(this.assetIdValue, account);
    this.balanceValueTarget.innerText = `${balance} ${this.assetSymbolValue}`;
    this.balanceLinkTarget.href = `https://scan.mvm.dev/address/${account}/tokens#address-tabs`;
  }

  metaMaskIconTargetConnected() {
    if (Wallet.provider === 'MetaMask') {
      this.metaMaskIconTarget.classList.remove('hidden');
    }
  }

  walletConnectIconTargetConnected() {
    if (Wallet.provider === 'WalletConnect') {
      this.walletConnectIconTarget.classList.remove('hidden');
    }
  }

  coinbaseIconTargetConnected() {
    if (Wallet.provider === 'Coinbase') {
      this.coinbaseIconTarget.classList.remove('hidden');
    }
  }

  async pay(event) {
    event.preventDefault();

    await Wallet.switchToMVM();
    if (!Wallet.isCurrentNetworkMvm()) {
      notify('Switch to MVM Chain before paying', 'danger');
      return;
    }

    const { assetId, symbol, amount, receivers, threshold, memo, payerId } =
      event.params;

    this.lockButton();
    try {
      notify(`Invoking ${Wallet.provider} to pay ${amount} ${symbol}`, 'info');

      await Wallet.payWithMVM(
        { assetId, symbol, amount, receivers, threshold, memo, payerId },
        (hash) => {
          notify('Transaction submitted', 'success');
          this.buttonTarget.classList.add('hidden');

          if (this.afterSubmitActionValue === 'wait' && this.hasWaitTarget) {
            this.waitTarget.classList.remove('hidden');
          } else if (
            this.afterSubmitActionValue === 'finish' &&
            this.hasFinishTarget
          ) {
            this.finishTarget.classList.remove('hidden');
          }

          this.scanTransactionLinkTargets.forEach((target) => {
            target.href = `https://scan.mvm.dev/tx/${hash}`;
            target.classList.remove('hidden');
          });
          this.unlockButton();
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
