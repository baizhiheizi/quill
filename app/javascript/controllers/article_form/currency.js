// Currency / price math. The asset dropdown and price presets both
// drive `currencyPriceUsdValue`, which `changeCurrency` updates from the
// selected option's `data-price-usd` attribute (and re-renders the
// currency icon, chain icon, and symbol next to the price input).
// `calCryptoFromUsd` is the shared calculator: USD / priceUsd → crypto
// amount, written to both the hidden `price_crypto` field (submitted
// with the form) and the visible crypto display next to the price
// input. It also re-runs readiness + queues an autosave since pricing
// changes should persist immediately.
export default class Currency {
  constructor(controller) {
    this.controller = controller;
  }

  priceUsdChanged() {
    this.calCryptoFromUsd();
  }

  changeCurrency(event) {
    const controller = this.controller;
    const option = event.target.selectedOptions?.[0];
    if (!option) return;

    const priceUsd = parseFloat(option.dataset.priceUsd || "0");
    controller.currencyPriceUsdValue = Number.isNaN(priceUsd) ? 0 : priceUsd;

    if (controller.hasCurrencySymbolTarget) {
      controller.currencySymbolTarget.innerText =
        option.dataset.symbol || option.textContent.trim();
    }
    if (controller.hasCurrencyIconTarget && option.dataset.iconUrl) {
      controller.currencyIconTarget.src = option.dataset.iconUrl;
    }
    if (controller.hasCurrencyChainIconTarget && option.dataset.chainIconUrl) {
      controller.currencyChainIconTarget.src = option.dataset.chainIconUrl;
    }

    this.calCryptoFromUsd();
    controller.readiness.update();
    controller.autosave.queueAutosave();
  }

  calCryptoFromUsd() {
    const controller = this.controller;
    if (!controller.hasPriceUsdInputTarget) return;

    if (!controller.currencyPriceUsdValue) {
      controller.readiness.update();
      return;
    }

    const usdValue = parseFloat(controller.priceUsdInputTarget.value);
    if (Number.isNaN(usdValue) || usdValue <= 0) {
      controller.readiness.update();
      return;
    }

    const cryptoAmount = usdValue / controller.currencyPriceUsdValue;
    const rounded = parseFloat(cryptoAmount.toFixed(8));

    if (controller.hasPriceCryptoTarget) {
      controller.priceCryptoTarget.value = rounded;
    }
    if (controller.hasPriceCryptoDisplayTarget) {
      const symbol =
        controller.currencySymbolTarget?.textContent?.trim() ||
        controller.element.querySelector("#article_asset_id option:checked")?.dataset
          ?.symbol ||
        "";
      controller.priceCryptoDisplayTarget.innerText = `${rounded} ${symbol}`.trim();
    }
    controller.readiness.update();
  }

  setPricePreset(event) {
    const controller = this.controller;
    if (!controller.hasPriceUsdInputTarget) return;
    controller.priceUsdInputTarget.value = parseFloat(event.params.preset).toFixed(2);
    this.calCryptoFromUsd();
    controller.autosave.queueAutosave();
  }
}
