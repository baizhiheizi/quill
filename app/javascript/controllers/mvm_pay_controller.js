import { Controller } from '@hotwired/stimulus';
import { notify, showLoading, hideLoading } from '../utils';
import { balanceOf, MVM_CHAIN_ID, switchToMVM } from '../mvm/wallet';
import { payWithMVM } from '../mvm/pay';

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
  ];

  static values = {
    assetId: String,
    assetSymbol: String,
    afterSubmitAction: String,
  };

  async assetIdValueChanged() {
    if (!this.assetIdValue) return;
    if (!window.w3) return;

    const accounts = await w3.eth.getAccounts();
    const balance = await balanceOf(this.assetIdValue, accounts[0]);
    this.balanceValueTarget.innerText = `${balance} ${this.assetSymbolValue}`;
    this.balanceLinkTarget.href = `https://scan.mvm.dev/address/${accounts[0]}/tokens#address-tabs`;
  }

  metaMaskIconTargetConnected() {
    if (w3.provider === 'MetaMask') {
      this.metaMaskIconTarget.classList.remove('hidden');
    }
  }

  walletConnectIconTargetConnected() {
    if (w3.provider === 'WalletConnect') {
      this.walletConnectIconTarget.classList.remove('hidden');
    }
  }

  coinbaseIconTargetConnected() {
    if (w3.provider === 'Coinbase') {
      this.coinbaseIconTarget.classList.remove('hidden');
    }
  }

  async pay(event) {
    event.preventDefault();

    await switchToMVM();
    if (parseInt(w3.currentProvider.chainId) !== parseInt(MVM_CHAIN_ID)) {
      notify('Switch to MVM Chain before paying', 'danger');
      return;
    }

    const { assetId, symbol, amount, opponentIds, threshold, memo, mixinUuid } =
      event.params;

    this.lockButton();
    try {
      notify(`Invoking ${w3.provider} to pay ${amount} ${symbol}`, 'info');

      await payWithMVM(
        { assetId, symbol, amount, opponentIds, threshold, memo, mixinUuid },
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
