import { Controller } from "@hotwired/stimulus";
import * as Rails from '@rails/ujs';
import EasyMDE from 'easymde';

export default class extends Controller {
  static values = {
    autosave: Boolean
  }
  static targets = [
    "form", 
    "contentFields", 
    "optionFields", 
    "title",
    "content", 
    "preview", 
    "editButton", 
    "previewButton",
    "optionsButton"
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

  save() {
    Rails.fire(this.formTarget, 'submit');
  }

  edit() {
    this.activeContentForm();
    this.hidePreview();
    this.hideSettingsForm();
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
      this.activePreview();
      this.hideContentForm();
      this.hideSettingsForm();
    });
  }

  options() {
    this.activeSettingsForm();
    this.hideContentForm();
    this.hidePreview();
  }

  activeContentForm() {
    this.contentFieldsTarget.classList.remove("hidden");
    this.editButtonTarget.classList.add("border-b-2");
  }

  hideContentForm() {
    this.contentFieldsTarget.classList.add("hidden");
    this.editButtonTarget.classList.remove("border-b-2");
  }

  activeSettingsForm() {
    this.optionFieldsTarget.classList.remove("hidden");
    this.optionsButtonTarget.classList.add("border-b-2");
  }

  hideSettingsForm() {
    this.optionFieldsTarget.classList.add("hidden");
    this.optionsButtonTarget.classList.remove("border-b-2");
  }

  activePreview() {
    this.previewButtonTarget.classList.add("border-b-2");
    this.previewTarget.classList.remove("hidden");
  }

  hidePreview() {
    this.previewButtonTarget.classList.remove("border-b-2");
    this.previewTarget.classList.add("hidden");
    this.previewTarget.classList.innerHTML = "";
  }
}
