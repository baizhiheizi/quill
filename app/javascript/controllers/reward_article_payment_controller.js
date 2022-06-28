import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';

export default class extends Controller {
  static values = {
    traceId: String,
    articleUuid: String,
    selectedCurrency: String,
    identifier: String,
    minimalRewardAmount: Number,
    selectedAmountShare: Number,
  };
  static targets = [
    'currency',
    'currencyIcon',
    'currencyChainIcon',
    'currencySymbol',
    'amountShare',
    'amount',
    'payBox',
    'loading',
    'price',
    'state',
    'payButton',
  ];

  connect() {
    document.addEventListener('modal:ok', (event) => {
      const identifier = event.detail.identifier;

      if (identifier === this.identifierValue) {
        this.minimalRewardAmountValue = event.detail.minimalRewardAmount;
        this.selectedCurrencyValue = event.detail.assetId;
        this.currencyIconTarget.src = event.detail.iconUrl;
        this.currencyChainIconTarget.src = event.detail.chainIconUrl;

        this.currencySymbolTargets.forEach((target) => {
          target.innerText = event.detail.symbol;
        });
      }
    });
  }

  invokePayment() {
    if (!this.hasStateTarget) return;
    this.stateTarget.classList.remove('hidden');
  }

  selectCurrency(event) {
    this.selectedCurrencyValue = event.target.value;
  }

  selectAmountShare(event) {
    this.selectedAmountShareValue = event.currentTarget.dataset.amountShare;
  }

  selectedCurrencyValueChanged() {
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
