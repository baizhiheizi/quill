import { Controller } from "@hotwired/stimulus";
import EasyMDE from 'easymde';

export default class extends Controller {
  static values = {
    autosave: Boolean
  }
  static targets = [
    "form", 
    "title",
    "content", 
    "preview", 
    "editButton", 
    "previewButton"
  ]

  connect() {
    this.initMdEditor();
    if (this.autosave) {
      this.editor.codemirror.on("change", () => {
        Rails.fire(this.formTarget, 'submit')
      });
    }
  }

  initMdEditor() {
    this.editor = new EasyMDE(
      {
        element: this.contentTarget,
        placeholder: this.contentTarget.placeholder,
        status: false,
        spellChecker: false,
        sideBySideFullscreen: false,
        syncSideBySidePreviewScroll: false,
        toolbar: ["bold", "italic", "heading-2", "heading-3", "|" , "code", "quote", "|", "link", "image", "|", "guide"],
      }
    );
  }

  edit() {
    this.previewTarget.classList.add("hidden");
    this.formTarget.classList.remove("hidden");
    this.previewTarget.classList.innerHTML = "";
    this.editButtonTarget.classList.add("border-b-2");
    this.previewButtonTarget.classList.remove("border-b-2");
  }

  preview() {
    const content = this.editor.value();
    fetch("/articles/preview", {
      body: JSON.stringify({ content }),
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': (document.querySelector("meta[name='csrf-token']") || {}).content,
        'Content-Type': 'application/json',
      },
      method: "POST",
    })
    .then(response => response.json())
    .then(data => {
      this.previewTarget.innerHTML = data.html;
      this.formTarget.classList.add("hidden");
      this.previewTarget.classList.remove("hidden");
      this.editButtonTarget.classList.remove("border-b-2");
      this.previewButtonTarget.classList.add("border-b-2");
    });
  }
}
