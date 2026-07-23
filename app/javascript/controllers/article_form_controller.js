import { Controller } from "@hotwired/stimulus";
import { debounce } from "underscore";
import Autosave from "./article_form/autosave";
import UI from "./article_form/ui";
import Draft from "./article_form/draft";
import Content from "./article_form/content";
import Currency from "./article_form/currency";
import Readiness from "./article_form/readiness";
import Conflict from "./article_form/conflict";

// Thin orchestrator. Each concern lives in its own module under
// `article_form/`; the controller's job is to wire Stimulus lifecycle
// callbacks (data-action, value-changed, target-connected) to the
// right module, own the cross-module shared helpers (`setSaveStatus`,
// `contentValue`, `confirmLeaving`), and hold module instances so they
// can call back into each other when needed.
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
    this.autosave = new Autosave(this);
    this.ui = new UI(this);
    this.draft = new Draft(this);
    this.content = new Content(this);
    this.currency = new Currency(this);
    this.readiness = new Readiness(this);
    this.conflict = new Conflict(this);

    this.debouncedAutosave = debounce(() => this.autosave.runAutosave(), 1000);
    this.inFlight = false;
    this.pendingAutosave = false;
    this.boundKeydown = (event) => this.ui.handleKeydown(event);
    this.boundPreviewMessage = (event) => this.ui.handlePreviewMessage(event);
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
    this.draft.recoverDraftWhenReady();
    this.readiness.update();
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

  // Data-action proxies — Stimulus dispatches these by name from the
  // form's data-action attributes, so each must remain a top-level
  // method on the controller.
  autosave() {
    this.autosave.autosave();
  }

  queueAutosave() {
    this.autosave.queueAutosave();
  }

  toggleFocusMode() {
    this.ui.toggleFocusMode();
  }

  toggleSettingsRail() {
    this.ui.toggleSettingsRail();
  }

  togglePreview() {
    this.ui.togglePreview();
  }

  closePreview() {
    this.ui.closePreview();
  }

  exitOverlay() {
    this.ui.exitOverlay();
  }

  changeCurrency(event) {
    this.currency.changeCurrency(event);
  }

  setPricePreset(event) {
    this.currency.setPricePreset(event);
  }

  keepMyVersion() {
    this.conflict.keepMyVersion();
  }

  // Stimulus value-changed callbacks — Stimulus invokes these by name
  // (`focusModeValueChanged`, etc.) when the matching value mutates.
  focusModeValueChanged() {
    this.ui.focusModeChanged();
  }

  previewOpenValueChanged() {
    this.ui.previewOpenChanged();
  }

  settingsRailOpenValueChanged() {
    this.ui.settingsRailOpenChanged();
  }

  saveStatusValueChanged() {
    this.ui.saveStatusChanged();
  }

  dirtyValueChanged() {
    this.ui.saveStatusChanged();
  }

  currencyPriceUsdValueChanged() {
    this.currency.priceUsdChanged();
  }

  // Stimulus target-connected callbacks — fired when the matching
  // target enters the DOM. We defer draft recovery until both the form
  // and content targets are mounted so the rich-text editor is ready.
  formTargetConnected() {
    this.draft.targetConnected();
  }

  contentTargetConnected() {
    this.draft.targetConnected();
  }

  // Shared helpers used by multiple modules. Modules reach these via
  // `this.controller.setSaveStatus(...)`, `this.controller.contentValue`,
  // and `this.controller.confirmLeaving`.
  setSaveStatus(status) {
    this.saveStatusValue = status;
    if (!this.hasSaveStatusTarget) return;

    this.saveStatusTarget.dataset.saveStatus = status;
  }

  get contentValue() {
    return this.content.getValue();
  }

  setContentValue(value) {
    this.content.setValue(value);
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
}
