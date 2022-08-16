import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';
import { hideLoading, showLoading } from '../../javascript/utils';

export default class extends Controller {
  static values = {
    followId: String,
    identifier: String,
    payAssetId: String,
    type: String,
  };

  static targets = [
    'selectCurrencyButton',
    'currencyIcon',
    'currencyChainIcon',
    'currencySymbol',
    'payButton',
    'state',
  ];

  connect() {
    document
      .querySelector('#modal')
      .addEventListener('modal-component:ok', (event) => {
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
    if (!this.payAssetIdValue) return;

    this.updatePreOrder();
  }

  updatePreOrder() {
    showLoading();
    get(
      `/pre_orders/${this.followIdValue}?pay_asset_id=${this.payAssetIdValue}`,
      {
        contentType: 'application/json',
        responseKind: 'turbo-stream',
      },
    ).then(() => hideLoading());
  }

  pay() {
    this.selectCurrencyButtonTarget.disabled = true;
    if (this.typeValue !== 'MVMPreOrder') {
      this.stateTarget.classList.remove('hidden');
    }
  }
}
