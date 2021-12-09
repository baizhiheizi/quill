import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js'

export default class extends Controller {
  static values = {
    articleUuid: String,
    selectedCurrency: String
  }
  static targets = ["currency", "payBox", "loading", "price", "payLink"]

  connect() {
  }

  select(e) {
    const selected = e.currentTarget.dataset.assetId
    this.selectedCurrencyValue = selected;
    this.fetchPreOrder();
  }

  selectedCurrencyValueChanged() {
    this.currencyTargets.forEach((target) => {
      if (target.dataset.assetId === this.selectedCurrencyValue) {
        target.classList.add("border-blue-500", "text-blue-500");
      } else {
        target.classList.remove("border-blue-500", "text-blue-500");
      }
    })
  }

  fetchPreOrder() {
    this.payBoxTarget.innerHTML = this.loadingTarget.innerHTML;
    post("/payments", {
      body: { 
        uuid: this.articleUuidValue, 
        asset_id: this.selectedCurrencyValue
      },
      contentType: "application/json",
      responseKind: "turbo-stream"
    })
  }
}
