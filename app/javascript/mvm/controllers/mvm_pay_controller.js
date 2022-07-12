import { Controller } from '@hotwired/stimulus';
import { notify, showLoading, hideLoading } from '../../utils';
import { initWallet } from '../wallet';
import { payWithMVM } from '../pay';

export default class extends Controller {
  static targets = [
    'button',
    'metaMaskIcon',
    'walletConnectIcon',
    'wait',
    'finish',
    'scanTransactionLink',
  ];

  static values = {
    afterSubmitAction: String,
  };

  async initialize() {
    try {
      await initWallet();
    } catch (error) {
      notify(error.message, 'danger');
    }
  }

  connect() {
    console.log(this.afterSubmitActionValue);
  }

  afterSubmitActionValueChanged() {
    console.log(this.afterSubmitActionValue);
  }

  metaMaskIconTargetConnected() {
    window.w3 &&
      w3.currentProvider.isMetaMask &&
      this.metaMaskIconTarget.classList.remove('hidden');
  }

  walletConnectIconTargetConnected() {
    window.w3 &&
      w3.currentProvider.wc &&
      this.walletConnectIconTarget.classList.remove('hidden');
  }

  async pay(event) {
    event.preventDefault();

    const { assetId, symbol, amount, opponentIds, threshold, memo, mixinUuid } =
      event.params;

    this.lockButton();
    try {
      notify(
        `Invoking ${
          w3.currentProvider.isMetaMask
            ? 'MetaMask'
            : w3.currentProvider.wc.peerMeta.name
        } to pay ${amount} ${symbol}`,
        'info',
      );
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
