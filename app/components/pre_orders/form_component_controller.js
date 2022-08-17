import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    type: String,
    amount: Number,
    priceUsd: Number,
    itemId: String,
    itemType: String,
    assetId: String,
    orderType: String,
  };

  static targets = [
    'type',
    'typeInput',
    'amountInput',
    'amountOption',
    'amountTag',
    'amountUsdTag',
    'mvmTips',
  ];

  async checkMVM() {
    if (this.typeValue === 'MVMPreOrder') {
      await Wallet.switchToMVM();

      if (!Wallet.isCurrentNetworkMvm()) {
        let input = this.submitButtonTarget.querySelector('input[type=submit]');
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
      }
    } else {
      this.mvmTipsTarget.classList.add('hidden');
    }
  }

  amountValueChanged() {
    this.amountInputTargets.forEach((target) => {
      target.value = this.amountValue;
    });
    if (this.hasAmountTagTarget) {
      this.amountTagTarget.innerText = this.amountValue;
    }
    if (this.hasAmountUsdTagTarget) {
      this.amountUsdTagTarget.innerText = (
        this.amountValue * this.priceUsdValue
      ).toFixed(4);
    }
    this.amountOptionTargets.forEach((target) => {
      const amount = target.dataset.preOrdersFormComponentAmountParam;
      if (amount == this.amountValue) {
        target.classList.add('border-2', 'border-primary');
        target.classList.remove('border-zinc-200');
        target.querySelector('.checkmark').classList.remove('hidden');
      } else {
        target.classList.remove('border-2', 'border-primary');
        target.classList.add('border-zinc-200');
        target.querySelector('.checkmark').classList.add('hidden');
      }
    });
  }

  select(event) {
    const { type } = event.params;
    this.typeValue = type;
  }

  updateAmount(event) {
    const { amount } = event.params;
    this.amountValue = amount;
  }
}
