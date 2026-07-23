// UI state transitions for the article editor: focus mode (chrome-less
// writing surface), preview overlay (iframe with the rendered article),
// settings rail (sidebar with author/paywall controls), save-status
// badge + publish button gating, and the turbo:before-visit leave
// warning. Stimulus value-changed callbacks land here too — Stimulus
// dispatches them by name (`focusModeValueChanged`, etc.) so the
// controller exposes thin proxies that forward into these methods.
export default class UI {
  constructor(controller) {
    this.controller = controller;
  }

  disconnect() {
    document.removeEventListener(
      "turbo:before-visit",
      this.controller.confirmLeaving,
    );
  }

  handleKeydown(event) {
    if (event.key !== "Escape") return;

    if (this.controller.previewOpenValue) {
      this.closePreview();
      return;
    }

    if (this.controller.focusModeValue) {
      this.controller.focusModeValue = false;
    }
  }

  handlePreviewMessage(event) {
    if (event.data !== "close-preview" || !this.controller.previewOpenValue)
      return;
    if (event.origin !== window.location.origin) return;

    if (
      this.controller.hasPreviewPanelTarget &&
      event.source !== this.controller.previewPanelTarget.contentWindow
    ) {
      return;
    }

    this.closePreview();
  }

  focusModeChanged() {
    this.controller.element.classList.toggle(
      "article-editor--focus",
      this.controller.focusModeValue,
    );
  }

  previewOpenChanged() {
    this.controller.element.classList.toggle(
      "article-editor--preview-open",
      this.controller.previewOpenValue,
    );
  }

  settingsRailOpenChanged() {
    const controller = this.controller;
    controller.element.classList.toggle(
      "article-editor--settings-open",
      controller.settingsRailOpenValue,
    );
    if (controller.hasSettingsToggleTarget) {
      controller.settingsToggleTarget.setAttribute(
        "aria-expanded",
        String(controller.settingsRailOpenValue),
      );
    }
  }

  toggleFocusMode() {
    this.controller.focusModeValue = !this.controller.focusModeValue;
  }

  toggleSettingsRail() {
    this.controller.settingsRailOpenValue =
      !this.controller.settingsRailOpenValue;
  }

  togglePreview() {
    const controller = this.controller;
    if (!controller.previewUrlValue) return;

    controller.previewOpenValue = !controller.previewOpenValue;
    if (controller.hasPreviewPanelTarget) {
      controller.previewPanelTarget.classList.toggle(
        "hidden",
        !controller.previewOpenValue,
      );
      if (controller.previewOpenValue) {
        controller.previewPanelTarget.src = `${controller.previewUrlValue}?t=${Date.now()}`;
      }
    }
  }

  closePreview() {
    const controller = this.controller;
    controller.previewOpenValue = false;
    if (controller.hasPreviewPanelTarget) {
      controller.previewPanelTarget.classList.add("hidden");
      controller.previewPanelTarget.removeAttribute("src");
    }
  }

  exitOverlay() {
    if (this.controller.previewOpenValue) {
      this.closePreview();
    }

    if (this.controller.focusModeValue) {
      this.controller.focusModeValue = false;
    }
  }

  saveStatusChanged() {
    this.updateLeaveWarning();
    const controller = this.controller;
    if (controller.hasPublishButtonTarget) {
      const blocked = ["dirty", "saving", "error", "conflict"].includes(
        controller.saveStatusValue,
      );
      controller.publishButtonTarget.disabled = blocked;
      controller.publishButtonTarget.classList.toggle(
        "cursor-not-allowed",
        blocked,
      );
      controller.publishButtonTarget.classList.toggle("opacity-60", blocked);
      controller.publishButtonTarget.classList.toggle(
        "cursor-pointer",
        !blocked,
      );
    }
  }

  updateLeaveWarning() {
    const controller = this.controller;
    const atRisk = ["dirty", "saving", "error"].includes(
      controller.saveStatusValue,
    );
    if (atRisk) {
      document.addEventListener(
        "turbo:before-visit",
        controller.confirmLeaving,
      );
    } else {
      document.removeEventListener(
        "turbo:before-visit",
        controller.confirmLeaving,
      );
    }
  }
}
