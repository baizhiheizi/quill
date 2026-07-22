import { Controller } from "@hotwired/stimulus";
import { patch, post } from "@rails/request.js";
import { debounce } from "underscore";

export default class extends Controller {
  static values = {
    draftKey: String,
    createUrl: String,
    updateUrl: String,
    articleUuid: String,
    newRecord: Boolean,
    articlePublished: Boolean,
    currencyPriceUsd: Number,
    dirty: Boolean,
    saveStatus: { type: String, default: "idle" },
    lockVersion: { type: Number, default: 0 },
    updatedAt: Number,
    settingsRailOpen: { type: Boolean, default: false },
    focusMode: { type: Boolean, default: false },
    previewOpen: { type: Boolean, default: false },
    previewUrl: String,
    readinessTranslations: Object,
  };

  static targets = [
    "form",
    "contentFields",
    "settingsRail",
    "settingsToggle",
    "writingSurface",
    "editorChrome",
    "saveStatus",
    "title",
    "content",
    "currencyIcon",
    "currencyChainIcon",
    "currencySymbol",
    "priceUsdInput",
    "priceCrypto",
    "priceCryptoDisplay",
    "publishButton",
    "readinessIndicator",
    "previewPanel",
    "floatingExit",
  ];

  initialize() {
    this.runAutosave = this.runAutosave.bind(this);
    this.debouncedAutosave = debounce(this.runAutosave, 1000);
    this.inFlight = false;
    this.pendingAutosave = false;
    this.boundKeydown = this.handleKeydown.bind(this);
    this.boundPreviewMessage = this.handlePreviewMessage.bind(this);
    this.confirmLeaving = this.confirmLeaving.bind(this);
    this.boundRevenueQueueAutosave = () => this.queueAutosave();
  }

  connect() {
    document.addEventListener("keydown", this.boundKeydown);
    window.addEventListener("message", this.boundPreviewMessage);
    this.element.addEventListener(
      "article-revenue:queue-autosave",
      this.boundRevenueQueueAutosave,
    );
    this.recoverDraftWhenReady();
    this.updateReadiness();
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown);
    window.removeEventListener("message", this.boundPreviewMessage);
    this.element.removeEventListener(
      "article-revenue:queue-autosave",
      this.boundRevenueQueueAutosave,
    );
    document.removeEventListener("turbo:before-visit", this.confirmLeaving);
  }

  handleKeydown(event) {
    if (event.key !== "Escape") return;

    if (this.previewOpenValue) {
      this.closePreview();
      return;
    }

    if (this.focusModeValue) {
      this.focusModeValue = false;
    }
  }

  handlePreviewMessage(event) {
    if (event.data !== "close-preview" || !this.previewOpenValue) return;
    if (event.origin !== window.location.origin) return;

    if (
      this.hasPreviewPanelTarget &&
      event.source !== this.previewPanelTarget.contentWindow
    ) {
      return;
    }

    this.closePreview();
  }

  focusModeValueChanged() {
    this.element.classList.toggle("article-editor--focus", this.focusModeValue);
  }

  previewOpenValueChanged() {
    this.element.classList.toggle(
      "article-editor--preview-open",
      this.previewOpenValue,
    );
  }

  settingsRailOpenValueChanged() {
    this.element.classList.toggle(
      "article-editor--settings-open",
      this.settingsRailOpenValue,
    );
    if (this.hasSettingsToggleTarget) {
      this.settingsToggleTarget.setAttribute(
        "aria-expanded",
        String(this.settingsRailOpenValue),
      );
    }
  }

  toggleFocusMode() {
    this.focusModeValue = !this.focusModeValue;
  }

  toggleSettingsRail() {
    this.settingsRailOpenValue = !this.settingsRailOpenValue;
  }

  togglePreview() {
    if (!this.previewUrlValue) return;

    this.previewOpenValue = !this.previewOpenValue;
    if (this.hasPreviewPanelTarget) {
      this.previewPanelTarget.classList.toggle(
        "hidden",
        !this.previewOpenValue,
      );
      if (this.previewOpenValue) {
        this.previewPanelTarget.src = `${this.previewUrlValue}?t=${Date.now()}`;
      }
    }
  }

  closePreview() {
    this.previewOpenValue = false;
    if (this.hasPreviewPanelTarget) {
      this.previewPanelTarget.classList.add("hidden");
      this.previewPanelTarget.removeAttribute("src");
    }
  }

  exitOverlay() {
    if (this.previewOpenValue) {
      this.closePreview();
    }

    if (this.focusModeValue) {
      this.focusModeValue = false;
    }
  }

  saveStatusValueChanged() {
    this.updateLeaveWarning();
    if (this.hasPublishButtonTarget) {
      const blocked = ["dirty", "saving", "error", "conflict"].includes(
        this.saveStatusValue,
      );
      this.publishButtonTarget.disabled = blocked;
      this.publishButtonTarget.classList.toggle("cursor-not-allowed", blocked);
      this.publishButtonTarget.classList.toggle("opacity-60", blocked);
      this.publishButtonTarget.classList.toggle("cursor-pointer", !blocked);
    }
  }

  dirtyValueChanged() {
    this.saveStatusValueChanged();
  }

  updateLeaveWarning() {
    const atRisk = ["dirty", "saving", "error"].includes(this.saveStatusValue);
    if (atRisk) {
      document.addEventListener("turbo:before-visit", this.confirmLeaving);
    } else {
      document.removeEventListener("turbo:before-visit", this.confirmLeaving);
    }
  }

  confirmLeaving(event) {
    if (
      confirm(
        "You have unsaved changes that haven't reached the server yet. Leave anyway?",
      ) === false
    ) {
      event.preventDefault();
    }
  }

  formTargetConnected() {
    this.recoverDraftWhenReady();
  }

  contentTargetConnected() {
    this.recoverDraftWhenReady();
  }

  recoverDraftWhenReady() {
    if (!this.hasContentTarget) return;
    this.recoverDraft();
  }

  queueAutosave() {
    if (this.articlePublishedValue && !this.canEditPublishedFields()) return;
    if (!this.hasMeaningfulInput()) return;

    this.setSaveStatus("dirty");
    this.debouncedAutosave();
  }

  autosave() {
    this.updateReadiness();
    this.queueAutosave();
  }

  async runAutosave() {
    if (!this.hasFormTarget) return;
    if (!this.hasMeaningfulInput()) return;

    if (this.inFlight) {
      this.pendingAutosave = true;
      return;
    }

    this.inFlight = true;
    this.setSaveStatus("saving");

    const formData = this.buildFormData();

    try {
      if (this.newRecordValue) {
        const response = await post(this.createUrlValue, {
          body: formData,
          responseKind: "json",
        });

        if (response.ok) {
          const data = await response.json;
          this.promoteNewRecord(data);
          this.clearDraft();
          this.setSaveStatus("saved");
          this.dirtyValue = false;
        } else {
          this.persistLocalDraft();
          this.setSaveStatus("error");
          setTimeout(() => this.runAutosave(), 2000);
        }
      } else {
        const response = await patch(this.updateUrlValue, {
          body: formData,
          responseKind: "turbo-stream",
        });

        if (response.ok) {
          this.syncLockVersionFromMeta();
          this.clearDraft();
          this.setSaveStatus("saved");
          this.dirtyValue = false;
          this.removeConflictResolution();
        } else if (response.statusCode === 409) {
          // request.js only auto-renders turbo streams for 200/422 — apply 409 manually
          if (response.isTurboStream) {
            await response.renderTurboStream();
          }
          this.syncLockVersionFromMeta();
          this.setSaveStatus("conflict");
        } else {
          this.persistLocalDraft();
          this.setSaveStatus("error");
          setTimeout(() => this.runAutosave(), 2000);
        }
      }
    } catch {
      this.persistLocalDraft();
      this.setSaveStatus("error");
      setTimeout(() => this.runAutosave(), 2000);
    } finally {
      this.inFlight = false;
      if (this.pendingAutosave) {
        this.pendingAutosave = false;
        this.runAutosave();
      }
    }
  }

  promoteNewRecord({ uuid, edit_path, lock_version }) {
    this.newRecordValue = false;
    this.articleUuidValue = uuid;
    this.updateUrlValue = edit_path.replace(/\/edit\/?$/, "");
    this.lockVersionValue = lock_version || 0;
    this.previewUrlValue = `${this.updateUrlValue}/preview`;

    const methodInput = this.formTarget.querySelector('input[name="_method"]');
    if (methodInput) {
      methodInput.value = "patch";
    }

    window.history.replaceState(null, "", edit_path);
  }

  syncLockVersionFromMeta() {
    const meta = document.getElementById("article-form-meta");
    const param = meta?.querySelector("[data-article-form-lock-version-param]");
    if (param?.dataset.articleFormLockVersionParam) {
      this.lockVersionValue = parseInt(
        param.dataset.articleFormLockVersionParam,
        10,
      );
    }
  }

  buildFormData() {
    const formData = new FormData(this.formTarget);
    formData.set("article[lock_version]", this.lockVersionValue);
    return formData;
  }

  hasMeaningfulInput() {
    const title = this.element.querySelector("#article_title")?.value?.trim();
    const intro = this.element.querySelector("#article_intro")?.value?.trim();
    const content = this.contentValue?.trim();
    return Boolean(title || intro || content);
  }

  canEditPublishedFields() {
    return true;
  }

  setSaveStatus(status) {
    this.saveStatusValue = status;
    if (!this.hasSaveStatusTarget) return;

    this.saveStatusTarget.dataset.saveStatus = status;
  }

  persistLocalDraft() {
    const title = this.element.querySelector("#article_title")?.value;
    const intro = this.element.querySelector("#article_intro")?.value;
    const content = this.contentValue;

    localStorage.setItem(
      this.draftKeyValue,
      JSON.stringify({ title, intro, content, updatedAt: Date.now() }),
    );
  }

  recoverDraft() {
    const draft = localStorage.getItem(this.draftKeyValue);
    if (!draft) return;

    const { title, intro, content, updatedAt } = JSON.parse(draft);
    if (this.updatedAtValue && this.updatedAtValue > updatedAt) return;

    const titleEl = this.element.querySelector("#article_title");
    if (titleEl && title) titleEl.value = title;

    const introEl = this.element.querySelector("#article_intro");
    if (introEl && intro) {
      introEl.value = intro;
      introEl.style.height = "";
      introEl.style.height = `${introEl.scrollHeight}px`;
    }

    this.setContentValue(content);
    this.setSaveStatus("error");
  }

  clearDraft() {
    localStorage.removeItem(this.draftKeyValue);
  }

  get contentValue() {
    if (!this.hasContentTarget) return "";

    const target = this.contentTarget;
    if (target.tagName === "LEXXY-EDITOR") return target.value ?? "";
    if (target.tagName === "INPUT" || target.tagName === "TEXTAREA") {
      return target.value;
    }

    const hiddenInput = target.querySelector('input[name="article[content]"]');
    if (hiddenInput) return hiddenInput.value;

    return target.value ?? target.textContent ?? "";
  }

  setContentValue(content) {
    if (!this.hasContentTarget) return;

    const target = this.contentTarget;
    const editor =
      target.tagName === "LEXXY-EDITOR"
        ? target
        : this.contentFieldsTarget?.querySelector("lexxy-editor");

    if (editor) {
      editor.value = content;
      return;
    }

    const hiddenInput =
      target.tagName === "INPUT"
        ? target
        : target.querySelector('input[name="article[content]"]');

    if (hiddenInput) hiddenInput.value = content;
  }

  currencyPriceUsdValueChanged() {
    this.calCryptoFromUsd();
  }

  changeCurrency(event) {
    const option = event.target.selectedOptions?.[0];
    if (!option) return;

    const priceUsd = parseFloat(option.dataset.priceUsd || "0");
    this.currencyPriceUsdValue = Number.isNaN(priceUsd) ? 0 : priceUsd;

    if (this.hasCurrencySymbolTarget) {
      this.currencySymbolTarget.innerText =
        option.dataset.symbol || option.textContent.trim();
    }
    if (this.hasCurrencyIconTarget && option.dataset.iconUrl) {
      this.currencyIconTarget.src = option.dataset.iconUrl;
    }
    if (this.hasCurrencyChainIconTarget && option.dataset.chainIconUrl) {
      this.currencyChainIconTarget.src = option.dataset.chainIconUrl;
    }

    this.calCryptoFromUsd();
    this.updateReadiness();
    this.queueAutosave();
  }

  calCryptoFromUsd() {
    if (!this.hasPriceUsdInputTarget) return;

    if (!this.currencyPriceUsdValue) {
      this.updateReadiness();
      return;
    }

    const usdValue = parseFloat(this.priceUsdInputTarget.value);
    if (Number.isNaN(usdValue) || usdValue <= 0) {
      this.updateReadiness();
      return;
    }

    const cryptoAmount = usdValue / this.currencyPriceUsdValue;
    const rounded = parseFloat(cryptoAmount.toFixed(8));

    if (this.hasPriceCryptoTarget) {
      this.priceCryptoTarget.value = rounded;
    }
    if (this.hasPriceCryptoDisplayTarget) {
      const symbol =
        this.currencySymbolTarget?.textContent?.trim() ||
        this.element.querySelector("#article_asset_id option:checked")?.dataset
          ?.symbol ||
        "";
      this.priceCryptoDisplayTarget.innerText = `${rounded} ${symbol}`.trim();
    }
    this.updateReadiness();
  }

  setPricePreset(event) {
    if (!this.hasPriceUsdInputTarget) return;
    this.priceUsdInputTarget.value = parseFloat(event.params.preset).toFixed(2);
    this.calCryptoFromUsd();
    this.queueAutosave();
  }

  keepMyVersion() {
    this.syncLockVersionFromMeta();
    this.setSaveStatus("idle");
    this.removeConflictResolution();
    this.queueAutosave();
  }

  removeConflictResolution() {
    document.getElementById("conflict-resolution")?.remove();
  }

  updateReadiness() {
    if (!this.hasReadinessIndicatorTarget || this.newRecordValue) return;

    const blockers = [];
    const title = this.element.querySelector("#article_title")?.value?.trim();
    const intro = this.element.querySelector("#article_intro")?.value?.trim();
    const usdValue = this.hasPriceUsdInputTarget
      ? parseFloat(this.priceUsdInputTarget.value)
      : NaN;

    if (!title) blockers.push("title");
    if (!intro) blockers.push("intro");
    if (!this.contentValue?.trim()) blockers.push("content");
    if (
      !this.hasPriceUsdInputTarget ||
      Number.isNaN(usdValue) ||
      usdValue < 0.1
    ) {
      blockers.push("price");
    }

    const indicator = this.readinessIndicatorTarget;
    if (blockers.length === 0) {
      indicator.textContent = this.readinessLabel("ready");
      indicator.className =
        "hidden items-center rounded-full bg-success/15 px-2 py-0.5 text-xs font-medium text-success sm:inline-flex";
    } else {
      indicator.textContent = this.readinessThingsToFix(blockers.length);
      indicator.className =
        "hidden items-center rounded-full bg-warning/15 px-2 py-0.5 text-xs font-medium text-warning sm:inline-flex";
    }
  }

  readinessLabel(key) {
    const translations = this.readinessTranslationsValue || {};
    if (key === "ready") {
      return translations.ready || "Ready to publish";
    }
    return translations[key] || key;
  }

  readinessThingsToFix(count) {
    const translations = this.readinessTranslationsValue || {};
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
