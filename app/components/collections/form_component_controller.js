import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['form', 'priceUsd'];
  static values = {
    selectedAsset: String,
    currentPrice: Number,
    currencies: Array,
  };

  connect() {
    console.log('collection component connected');
  }

  currentPriceValueChanged() {
    this.calPriceUsd();
  }

  selectedAssetValueChanged() {
    this.calPriceUsd();
  }

  calPriceUsd() {
    const asset = this.currenciesValue.find((a) => a.asset_id == this.selectedAssetValue);

    if (this.hasPriceUsdTarget && asset) {
      this.priceUsdTarget.innerText = (asset.price_usd * this.currentPriceValue).toFixed(4);
    }
  }

  updateCurrentPrice(event) {
    this.currentPriceValue = event.currentTarget.value;
  }

  updateSelectedAsset(event) {
    this.selectedAssetValue = event.currentTarget.value;
  }
}
