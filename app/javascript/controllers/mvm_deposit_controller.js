import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';

export default class extends Controller {
  static values = {
    assetId: String,
    identifier: String,
  };

  static targets = [
    'qrcode',
    'currencyIcon',
    'currencyChainIcon',
    'currencySymbol',
  ];

  connect() {
    document.addEventListener('modal:ok', (event) => {
      const identifier = event.detail.identifier;

      if (identifier === this.identifierValue) {
        this.assetIdValue = event.detail.assetId;
        this.currencyIconTarget.src = event.detail.iconUrl;
        this.currencyChainIconTarget.src = event.detail.chainIconUrl;
        this.currencySymbolTarget.innerText = event.detail.symbol;
      }
    });
  }

  selectCurrency(event) {
    const asset_id = event.target.value;
    console.log(asset_id);
    get(`/dashboard/destination?asset_id=${asset_id}`, {
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    });
  }

  assetIdValueChanged() {
    if (!this.assetIdValue) return;

    this.fetchDesination();
  }

  fetchDesination() {
    get(`/dashboard/destination?asset_id=${this.assetIdValue}`, {
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    });
  }
}
