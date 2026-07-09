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
  };

  static targets = [
    "form",
    "contentFields",
    "settingsRail",
    "writingSurface",
    "editorChrome",
    "saveStatus",
    "title",
    "content",
    "currencyIcon",
    "currencyChainIcon",
    "currencySymbol",
    "priceUsd",
    "publishButton",
    "previewPanel",
    "floatingExit",
  ];

  initialize() {
    this.runAutosave = this.runAutosave.bind(this);
    this.debouncedAutosave = debounce(this.runAutosave, 1000);
    this.inFlight = false;
    this.pendingAutosave = false;
    this.boundModalOk = null;
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
    this.setupCurrencyModalListener();
    this.recoverDraftWhenReady();
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown);
    window.removeEventListener("message", this.boundPreviewMessage);
    this.element.removeEventListener(
      "article-revenue:queue-autosave",
      this.boundRevenueQueueAutosave,
    );
    if (this.boundModalOk) {
      document.removeEventListener("modal-component:ok", this.boundModalOk);
      this.boundModalOk = null;
    }
    document.removeEventListener("turbo:before-visit", this.confirmLeaving);
  }

  setupCurrencyModalListener() {
    if (this.articlePublishedValue || this.boundModalOk) return;

    this.boundModalOk = (event) => {
      const identifier = event.detail.identifier;
      if (identifier !== this.articleUuidValue) return;
      if (
        !this.hasCurrencyIconTarget ||
        !this.hasCurrencyChainIconTarget ||
        !this.hasCurrencySymbolTarget
      ) {
        return;
      }

      const assetSelect = this.element.querySelector("#article_asset_id");
      if (assetSelect) {
        assetSelect.value = event.detail.assetId;
      }

      this.currencyIconTarget.src = event.detail.iconUrl;
      this.currencyChainIconTarget.src = event.detail.chainIconUrl;
      this.currencySymbolTarget.innerText = event.detail.symbol;
      this.currencyPriceUsdValue = event.detail.priceUsd;
      this.queueAutosave();
    };
    document.addEventListener("modal-component:ok", this.boundModalOk);
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
        } else if (response.statusCode === 409) {
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
    this.setupCurrencyModalListener();
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
    if (!this.currencyPriceUsdValue || !this.hasPriceUsdTarget) return;
    this.calPriceUsd();
  }

  calPriceUsd() {
    if (!this.currencyPriceUsdValue || !this.hasPriceUsdTarget) return;

    const priceInput = this.element.querySelector(
      "input[name='article[price]']",
    );
    const price = (priceInput && priceInput.value) || 0;
    this.priceUsdTarget.innerText = (
      parseFloat(price) * parseFloat(this.currencyPriceUsdValue)
    ).toFixed(4);
  }

  // No-op: the views still bind `article-form#touchDirty` on reference
  // add/remove/select, but the method never existed — those edits already
  // trigger autosave via the revenue controller's calReferenceRatio path.
  // Kept intentionally empty to preserve existing behavior (issue #1839).
  touchDirty() {}
}
