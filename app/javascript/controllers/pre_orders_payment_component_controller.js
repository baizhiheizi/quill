import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";
import { hideLoading, showLoading } from "../utils";

export default class extends Controller {
  static values = {
    type: String,
    followId: String,
    identifier: String,
    payAssetId: String,
  };

  static targets = [
    "selectCurrencyButton",
    "currencyIcon",
    "currencyChainIcon",
    "currencySymbol",
    "state",
    "otherPayments",
  ];

  connect() {
    const modal = document.querySelector("#modal");
    if (!modal) return;

    // Bind handler once and keep a reference so disconnect() can remove it.
    // The `#modal` turbo frame is a long-lived singleton in the layout, and
    // Stimulus reconnects this controller on every Turbo navigation. Without
    // cleanup, the singleton accumulates stale listeners that all fire on
    // each `modal-component:ok` event.
    if (!this.boundModalOk) {
      this.boundModalOk = (event) => {
        const identifier = event.detail.identifier;

        if (identifier === this.identifierValue) {
          this.payAssetIdValue = event.detail.assetId;
          this.currencyIconTarget.src = event.detail.iconUrl;
          this.currencyChainIconTarget.src = event.detail.chainIconUrl;
          this.currencySymbolTarget.innerText = event.detail.symbol;
        }
      };
      modal.addEventListener("modal-component:ok", this.boundModalOk);
    }
  }

  disconnect() {
    const modal = document.querySelector("#modal");
    if (!modal?.removeEventListener) return;

    if (this.boundModalOk) {
      modal.removeEventListener("modal-component:ok", this.boundModalOk);
      this.boundModalOk = null;
    }
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
        contentType: "application/json",
        responseKind: "turbo-stream",
      },
    ).then(() => hideLoading());
  }

  pay() {
    if (this.hasStateTarget) {
      this.stateTarget.classList.remove("hidden");
    }
    if (this.hasOtherPaymentsTarget) {
      this.otherPaymentsTarget.classList.add("hidden");
    }
  }
}
