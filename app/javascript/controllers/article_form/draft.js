// localStorage-backed draft persistence and recovery. autosave calls
// `persistLocalDraft` whenever the server rejects a save (network error
// or 5xx) so the user does not lose work between attempts, and
// `clearDraft` after a successful save. On connect (and again whenever
// the form or content target is attached) the draft is replayed into the
// DOM — unless the server's `updatedAt` is newer than the draft, which
// means a different tab already saved over it.
export default class Draft {
  constructor(controller) {
    this.controller = controller;
  }

  targetConnected() {
    this.recoverDraftWhenReady();
  }

  recoverDraftWhenReady() {
    if (!this.controller.hasContentTarget) return;
    this.recoverDraft();
  }

  persistLocalDraft() {
    const controller = this.controller;
    const title = controller.element.querySelector("#article_title")?.value;
    const intro = controller.element.querySelector("#article_intro")?.value;
    const content = controller.contentValue;

    localStorage.setItem(
      controller.draftKeyValue,
      JSON.stringify({ title, intro, content, updatedAt: Date.now() }),
    );
  }

  recoverDraft() {
    const controller = this.controller;
    const draft = localStorage.getItem(controller.draftKeyValue);
    if (!draft) return;

    const { title, intro, content, updatedAt } = JSON.parse(draft);
    if (controller.updatedAtValue && controller.updatedAtValue > updatedAt) return;

    const titleEl = controller.element.querySelector("#article_title");
    if (titleEl && title) titleEl.value = title;

    const introEl = controller.element.querySelector("#article_intro");
    if (introEl && intro) {
      introEl.value = intro;
      introEl.style.height = "";
      introEl.style.height = `${introEl.scrollHeight}px`;
    }

    controller.setContentValue(content);
    controller.setSaveStatus("error");
  }

  clearDraft() {
    localStorage.removeItem(this.controller.draftKeyValue);
  }
}
