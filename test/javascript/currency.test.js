import { test, expect, describe } from "bun:test";
import Currency from "../../app/javascript/controllers/article_form/currency";

// Minimal mock that satisfies the Stimulus target contract without a DOM.
// Each `has*Target` gate and `*Target` value mirrors how the production
// controller exposes its form fields to the Currency module.
function makeMockController(overrides = {}) {
  const controller = {
    currencyPriceUsdValue: 0,
    hasPriceUsdInputTarget: true,
    priceUsdInputTarget: { value: "0" },
    hasPriceCryptoTarget: true,
    priceCryptoTarget: { value: "" },
    hasPriceCryptoDisplayTarget: true,
    priceCryptoDisplayTarget: { innerText: "" },
    hasCurrencySymbolTarget: true,
    currencySymbolTarget: { textContent: " BTC", innerText: "" },
    element: { querySelector: () => null },
    readiness: { update: () => {} },
    autosave: { queueAutosave: () => {} },
    ...overrides,
  };
  return controller;
}

describe("Currency — calCryptoFromUsd", () => {
  test("converts USD to crypto by dividing by the asset unit price", () => {
    const controller = makeMockController({
      currencyPriceUsdValue: 50_000, // 1 BTC = $50,000
      priceUsdInputTarget: { value: "100" },
    });

    const currency = new Currency(controller);
    currency.calCryptoFromUsd();

    // 100 / 50000 = 0.002, rounded to 8 decimals
    expect(controller.priceCryptoTarget.value).toBe(0.002);
  });

  test("rounds to 8 decimal places", () => {
    const controller = makeMockController({
      currencyPriceUsdValue: 3, // 1 token = $3
      priceUsdInputTarget: { value: "1" },
    });

    const currency = new Currency(controller);
    currency.calCryptoFromUsd();

    // 1 / 3 = 0.33333333… → toFixed(8) = "0.33333333" → parseFloat = 0.33333333
    expect(controller.priceCryptoTarget.value).toBe(0.33333333);
  });

  test("updates the visible crypto display with the symbol", () => {
    const controller = makeMockController({
      currencyPriceUsdValue: 50_000,
      priceUsdInputTarget: { value: "250" },
      currencySymbolTarget: { textContent: " BTC", innerText: "" },
    });

    const currency = new Currency(controller);
    currency.calCryptoFromUsd();

    // 250 / 50000 = 0.005
    expect(controller.priceCryptoDisplayTarget.innerText).toBe("0.005 BTC");
  });

  test("skips when the asset has no USD price set", () => {
    const controller = makeMockController({
      currencyPriceUsdValue: 0,
      priceUsdInputTarget: { value: "100" },
    });

    const currency = new Currency(controller);
    currency.calCryptoFromUsd();

    // No crypto value should be written
    expect(controller.priceCryptoTarget.value).toBe("");
  });

  test("skips when the USD input is zero or negative", () => {
    const controller = makeMockController({
      currencyPriceUsdValue: 50_000,
      priceUsdInputTarget: { value: "0" },
    });

    const currency = new Currency(controller);
    currency.calCryptoFromUsd();

    expect(controller.priceCryptoTarget.value).toBe("");
  });

  test("skips when the USD input is not a number", () => {
    const controller = makeMockController({
      currencyPriceUsdValue: 50_000,
      priceUsdInputTarget: { value: "abc" },
    });

    const currency = new Currency(controller);
    currency.calCryptoFromUsd();

    expect(controller.priceCryptoTarget.value).toBe("");
  });
});

describe("Currency — setPricePreset", () => {
  test("sets the USD input to the preset and recalculates crypto", () => {
    const controller = makeMockController({
      currencyPriceUsdValue: 50_000,
      priceUsdInputTarget: { value: "0" },
    });

    const currency = new Currency(controller);
    currency.setPricePreset({ params: { preset: 9.99 } });

    expect(controller.priceUsdInputTarget.value).toBe("9.99");
    // 9.99 / 50000 = 0.0001998 → toFixed(8)
    expect(controller.priceCryptoTarget.value).toBe(0.0001998);
  });
});
