import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';

export default class extends Controller {
  static values = {
    articleUuid: String,
    selectedCurrency: String,
    identifier: String,
  };
  static targets = [
    'currencyIcon',
    'currencyChainIcon',
    'currencySymbol',
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
        this.selectedCurrencyValue = event.detail.assetId;
        this.currencyIconTarget.src = event.detail.iconUrl;
        this.currencyChainIconTarget.src = event.detail.chainIconUrl;
        this.currencySymbolTarget.innerText = event.detail.symbol;
      }
    });
  }

  invokePayment() {
    if (!this.hasStateTarget) return;
    this.stateTarget.classList.remove('hidden');
  }

  selectedCurrencyValueChanged() {
    if (!this.selectedCurrencyValue) return;
    this.fetchPreOrder();
  }

  fetchPreOrder() {
    this.payBoxTarget.innerHTML = this.loadingTarget.innerHTML;
    post('/payments', {
      body: {
        type: 'buy_article',
        uuid: this.articleUuidValue,
        asset_id: this.selectedCurrencyValue,
      },
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    });
  }
}
