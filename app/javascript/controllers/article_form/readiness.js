// Publish-readiness validation. The controller calls `update` from
// `connect()`, on every input change (via the `autosave` action), and
// whenever the user picks a new currency or price preset — anywhere
// the price or content might just have crossed the publishable
// threshold. The indicator next to the publish button reads the
// `data-save-status` attribute (driven by `setSaveStatus`) and the
// readiness translations come in via `readinessTranslationsValue`.
export default class Readiness {
  constructor(controller) {
    this.controller = controller;
  }

  update() {
    const controller = this.controller;
    if (!controller.hasReadinessIndicatorTarget || controller.newRecordValue) return;

    const blockers = [];
    const title = controller.element.querySelector("#article_title")?.value?.trim();
    const intro = controller.element.querySelector("#article_intro")?.value?.trim();
    const usdValue = controller.hasPriceUsdInputTarget
      ? parseFloat(controller.priceUsdInputTarget.value)
      : NaN;

    if (!title) blockers.push("title");
    if (!intro) blockers.push("intro");
    if (!controller.contentValue?.trim()) blockers.push("content");
    if (
      !controller.hasPriceUsdInputTarget ||
      Number.isNaN(usdValue) ||
      usdValue < 0.1
    ) {
      blockers.push("price");
    }

    const indicator = controller.readinessIndicatorTarget;
    if (blockers.length === 0) {
      indicator.textContent = this.label("ready");
      indicator.className =
        "hidden items-center rounded-full bg-success/15 px-2 py-0.5 text-xs font-medium text-success sm:inline-flex";
    } else {
      indicator.textContent = this.thingsToFix(blockers.length);
      indicator.className =
        "hidden items-center rounded-full bg-warning/15 px-2 py-0.5 text-xs font-medium text-warning sm:inline-flex";
    }
  }

  label(key) {
    const translations = this.controller.readinessTranslationsValue || {};
    if (key === "ready") {
      return translations.ready || "Ready to publish";
    }
    return translations[key] || key;
  }

  thingsToFix(count) {
    const translations = this.controller.readinessTranslationsValue || {};
    const thing =
      count === 1
        ? translations.thing || "thing"
        : translations.things || "things";
    const template =
      translations.things_to_fix ||
      "%{count} %{thing} to fix before publishing";
    return template
      .replace("%{count}", String(count))
      .replace("%{thing}", thing);
  }
}
