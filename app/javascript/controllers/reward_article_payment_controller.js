import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';

export default class extends Controller {
  static values = {
    traceId: String,
    articleUuid: String,
    selectedCurrency: String,
    minimalRewardAmount: Number,
    selectedAmountShare: Number,
  };
  static targets = [
    'currency',
    'currencyIcon',
    'amountShare',
    'amount',
    'payBox',
    'loading',
    'price',
    'payLink',
  ];

  connect() {}

  selectCurrency(event) {
    this.selectedCurrencyValue = event.target.value;
  }

  selectAmountShare(event) {
    this.selectedAmountShareValue = event.currentTarget.dataset.amountShare;
  }

  selectedCurrencyValueChanged() {
    this.currencyTargets.forEach((target) => {
      if (target.value === this.selectedCurrencyValue) {
        this.minimalRewardAmountValue = target.dataset.minimalAmount;
        this.currencyIconTarget.src = target.dataset.currencyIconUrl;
      }
    });
    this.fetchPreOrder();
  }

  selectedAmountShareValueChanged() {
    this.amountShareTargets.forEach((target) => {
      if (
        parseInt(target.dataset.amountShare) === this.selectedAmountShareValue
      ) {
        target.classList.add('border-blue-500', 'text-blue-500');
        this.amountTarget.innerText =
          this.minimalRewardAmountValue * this.selectedAmountShareValue;
      } else {
        target.classList.remove('border-blue-500', 'text-blue-500');
      }
    });
    this.fetchPreOrder();
  }

  minimalRewardAmountValueChanged() {
    this.amountShareTargets.forEach((target) => {
      target.innerText =
        this.minimalRewardAmountValue * target.dataset.amountShare;
    });
    this.amountTarget.innerText =
      this.minimalRewardAmountValue * this.selectedAmountShareValue;
  }

  fetchPreOrder() {
    this.payBoxTarget.innerHTML = this.loadingTarget.innerHTML;
    post('/payments', {
      body: {
        type: 'reward_article',
        uuid: this.articleUuidValue,
        asset_id: this.selectedCurrencyValue,
        amount: this.minimalRewardAmountValue * this.selectedAmountShareValue,
        trace_id: this.traceIdValue,
      },
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    });
  }
}
