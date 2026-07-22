import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "output", "imageTpl", "videoTpl", "audioTpl"];

  connect() {
    this.preview();
  }

  preview() {
    const input = this.inputTarget;
    if (!input.files || !input.files[0]) return;

    const file = input.files[0];
    const kind = file.type.split("/")[0];
    this.renderPreview(kind, URL.createObjectURL(file));
  }

  renderPreview(kind, url) {
    const tagName = kind === "image" ? "img" : kind;
    const targetProp = `${kind}TplTarget`;
    const hasTargetProp =
      `has${kind.charAt(0).toUpperCase() + kind.slice(1)}TplTarget`;

    if (this[hasTargetProp]) {
      const el = this[targetProp];
      el.src = url;
      el.classList.remove("hidden");
      if (kind !== "image") el.setAttribute("controls", true);
      this.outputTarget.replaceChildren(el);
    } else {
      const attrs = kind === "image" ? "" : " controls";
      this.outputTarget.innerHTML =
        `<${tagName} class="w-full" src=${url}${attrs}></${tagName}>`;
    }
  }
}
