import { patch, post } from "@rails/request.js";

// Autosave state machine. Triggered by the `autosave` Stimulus action
// (wired on every editable input in the article form), debounced 1s via
// `debouncedAutosave`, and gated by `hasMeaningfulInput` so empty new
// records do not POST. New records go to `createUrlValue`; existing
// records PATCH `updateUrlValue` with `article[lock_version]` for
// optimistic locking. 409 conflicts render the server's turbo-stream
// response into the DOM and surface the conflict banner; other failures
// persist a local draft so the user does not lose work, then retry 2s
// later.
export default class Autosave {
  constructor(controller) {
    this.controller = controller;
  }

  queueAutosave() {
    const controller = this.controller;
    if (controller.articlePublishedValue && !this.canEditPublishedFields()) return;
    if (!this.hasMeaningfulInput()) return;

    controller.setSaveStatus("dirty");
    controller.debouncedAutosave();
  }

  autosave() {
    this.controller.readiness.update();
    this.queueAutosave();
  }

  async runAutosave() {
    const controller = this.controller;
    if (!controller.hasFormTarget) return;
    if (!this.hasMeaningfulInput()) return;

    if (controller.inFlight) {
      controller.pendingAutosave = true;
      return;
    }

    controller.inFlight = true;
    controller.setSaveStatus("saving");

    const formData = this.buildFormData();

    try {
      if (controller.newRecordValue) {
        const response = await post(controller.createUrlValue, {
          body: formData,
          responseKind: "json",
        });

        if (response.ok) {
          const data = await response.json;
          this.promoteNewRecord(data);
          controller.draft.clearDraft();
          controller.setSaveStatus("saved");
          controller.dirtyValue = false;
        } else {
          controller.draft.persistLocalDraft();
          controller.setSaveStatus("error");
          setTimeout(() => this.runAutosave(), 2000);
        }
      } else {
        const response = await patch(controller.updateUrlValue, {
          body: formData,
          responseKind: "turbo-stream",
        });

        if (response.ok) {
          this.syncLockVersionFromMeta();
          controller.draft.clearDraft();
          controller.setSaveStatus("saved");
          controller.dirtyValue = false;
          controller.conflict.removeConflictResolution();
        } else if (response.statusCode === 409) {
          // request.js only auto-renders turbo streams for 200/422 — apply 409 manually
          if (response.isTurboStream) {
            await response.renderTurboStream();
          }
          this.syncLockVersionFromMeta();
          controller.setSaveStatus("conflict");
        } else {
          controller.draft.persistLocalDraft();
          controller.setSaveStatus("error");
          setTimeout(() => this.runAutosave(), 2000);
        }
      }
    } catch {
      controller.draft.persistLocalDraft();
      controller.setSaveStatus("error");
      setTimeout(() => this.runAutosave(), 2000);
    } finally {
      controller.inFlight = false;
      if (controller.pendingAutosave) {
        controller.pendingAutosave = false;
        this.runAutosave();
      }
    }
  }

  promoteNewRecord({ uuid, edit_path, lock_version }) {
    const controller = this.controller;
    controller.newRecordValue = false;
    controller.articleUuidValue = uuid;
    controller.updateUrlValue = edit_path.replace(/\/edit\/?$/, "");
    controller.lockVersionValue = lock_version || 0;
    controller.previewUrlValue = `${controller.updateUrlValue}/preview`;

    const methodInput = controller.formTarget.querySelector('input[name="_method"]');
    if (methodInput) {
      methodInput.value = "patch";
    }

    window.history.replaceState(null, "", edit_path);
  }

  syncLockVersionFromMeta() {
    const controller = this.controller;
    const meta = document.getElementById("article-form-meta");
    const param = meta?.querySelector("[data-article-form-lock-version-param]");
    if (param?.dataset.articleFormLockVersionParam) {
      controller.lockVersionValue = parseInt(
        param.dataset.articleFormLockVersionParam,
        10,
      );
    }
  }

  buildFormData() {
    const controller = this.controller;
    const formData = new FormData(controller.formTarget);
    formData.set("article[lock_version]", controller.lockVersionValue);
    return formData;
  }

  hasMeaningfulInput() {
    const controller = this.controller;
    const title = controller.element.querySelector("#article_title")?.value?.trim();
    const intro = controller.element.querySelector("#article_intro")?.value?.trim();
    const content = controller.contentValue?.trim();
    return Boolean(title || intro || content);
  }

  canEditPublishedFields() {
    return true;
  }
}
