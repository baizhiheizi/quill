// Content value abstraction across the article body's editor variants:
// LEXXY-EDITOR (default rich-text editor), raw TEXTAREA / INPUT fallback,
// and the hidden `<input name="article[content]">` the form posts.
//
// The controller exposes `contentValue` (getter) and `setContentValue`
// (setter) as thin proxies so existing call sites in autosave / draft /
// readiness keep their `this.contentValue` shape — only the actual
// element-resolution logic lives here.
export default class Content {
  constructor(controller) {
    this.controller = controller;
  }

  getValue() {
    const controller = this.controller;
    if (!controller.hasContentTarget) return "";

    const target = controller.contentTarget;
    if (target.tagName === "LEXXY-EDITOR") return target.value ?? "";
    if (target.tagName === "INPUT" || target.tagName === "TEXTAREA") {
      return target.value;
    }

    const hiddenInput = target.querySelector('input[name="article[content]"]');
    if (hiddenInput) return hiddenInput.value;

    return target.value ?? target.textContent ?? "";
  }

  setValue(content) {
    const controller = this.controller;
    if (!controller.hasContentTarget) return;

    const target = controller.contentTarget;
    const editor =
      target.tagName === "LEXXY-EDITOR"
        ? target
        : controller.contentFieldsTarget?.querySelector("lexxy-editor");

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
}
