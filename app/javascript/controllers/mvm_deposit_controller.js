import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";
import { NativeAssetId } from "../mvm/constants";

export default class extends Controller {
  static values = {
    assetId: String,
    assetSymbol: String,
    assetIconUrl: String,
    identifier: String,
  };

  static targets = [
    "qrcode",
    "currencyIcon",
    "currencyChainIcon",
    "currencySymbol",
    "addTokenButton",
  ];

  async connect() {
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
          this.assetIdValue = event.detail.assetId;
          this.assetSymbolValue = event.detail.symbol;
          this.assetIconUrlValue = event.detail.iconUrl;

          this.currencyIconTargets.forEach((icon) => {
            icon.src = event.detail.iconUrl;
          });
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

  addToken() {
    if (!this.assetIdValue) return;

    Wallet.addTokenToMetaMask(
      this.assetIdValue,
      this.assetSymbolValue,
      this.assetIconUrlValue,
    );
  }

  selectCurrency(event) {
    const asset_id = event.target.value;
    get(`/dashboard/destination?asset_id=${asset_id}`, {
      contentType: "application/json",
      responseKind: "turbo-stream",
    });
  }

  assetIdValueChanged() {
    if (!this.assetIdValue) return;
    this.fetchDesination();

    if (!this.hasAddTokenButtonTarget) return;
    if (
      window.ethereum &&
      window.ethereum.isMetaMask &&
      this.assetIdValue !== NativeAssetId
    ) {
      this.addTokenButtonTarget.classList.remove("hidden");
    } else {
      this.addTokenButtonTarget.classList.add("hidden");
    }
  }

  fetchDesination() {
    get(`/dashboard/destination?asset_id=${this.assetIdValue}`, {
      contentType: "application/json",
      responseKind: "turbo-stream",
    });
  }
}
