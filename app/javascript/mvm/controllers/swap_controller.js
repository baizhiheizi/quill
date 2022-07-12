import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';
import { debounce } from 'underscore';
import { XIN_ASSET_ID } from '../constants';

export default class extends Controller {
  static values = {
    payAssetId: String,
    payAmount: Number,
    fillAssetId: String,
    identifier: String,
  };
  static targets = [
    'currencyIcon',
    'currencyChainIcon',
    'currencySymbol',
    'loading',
    'fillAsset',
  ];

  initialize() {
    this.calFillAsset = this.calFillAsset.bind(this);
  }

  connect() {
    this.calFillAsset = debounce(this.calFillAsset, 1500);

    document
      .querySelector('#modal-slot')
      .addEventListener('modal:ok', (event) => {
        const identifier = event.detail.identifier;

        if (
          identifier === this.identifierValue &&
          event.detail.assetId !== XIN_ASSET_ID
        ) {
          this.payAssetIdValue = event.detail.assetId;
          this.currencyIconTarget.src = event.detail.iconUrl;
          this.currencyChainIconTarget.src = event.detail.chainIconUrl;
          this.currencySymbolTarget.innerText = event.detail.symbol;
          this.calFillAsset();
        }
      });
    this.calFillAsset();
  }

  setPayAmount(event) {
    this.payAmountValue = event.currentTarget.value;
    this.calFillAsset();
  }

  calFillAsset() {
    this.fillAssetTarget.innerHTML = this.loadingTarget.innerHTML;
    post('/mvm/swap', {
      body: {
        pay_asset_id: this.payAssetIdValue,
        pay_amount: this.payAmountValue,
        fill_asset_id: this.fillAssetIdValue,
      },
      responseKind: 'turbo_stream',
    });
  }
}
