import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';

export default class extends Controller {
  static values = {
    identifier: String,
    payAssetId: String,
    id: String,
  };

  static targets = ['currencyIcon', 'currencyChainIcon', 'currencySymbol'];

  connect() {
    document
      .querySelector('#modal-slot')
      .addEventListener('modal:ok', (event) => {
        const identifier = event.detail.identifier;

        if (identifier === this.identifierValue) {
          this.payAssetIdValue = event.detail.assetId;
          this.currencyIconTarget.src = event.detail.iconUrl;
          this.currencyChainIconTarget.src = event.detail.chainIconUrl;
          this.currencySymbolTarget.innerText = event.detail.symbol;
        }
      });
  }

  payAssetIdValueChanged() {
    this.updatePreOrder();
  }

  updatePreOrder() {
    get(`/pre_orders/${this.idValue}?pay_asset_id=${this.payAssetIdValue}`, {
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    });
  }
}
