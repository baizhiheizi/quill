import { Controller } from "@hotwired/stimulus";
import EasyMDE from 'easymde';

export default class extends Controller {
  static values = {
    autosave: Boolean,
    newRecord: Boolean,
    activeTab: String,
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
    "optionsButton",
    "authorRevenueRatio",
    "referenceRevenueRatio",
    "articleReferenceRevenueRatio"
  ]

  connect() {
    if (this.autosaveValue) {
      this.editor.codemirror.on("change", () => {
        this.save();
      });
    }
  }

  formTargetConnected() {
    this.initMdEditor();
    switch(this.activeTabValue) {
      case 'edit':
        this.edit();
        break;
      case 'preview':
        this.preview();
        break;
      case 'options':
        this.options();
        break;
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
    if (this.newRecordValue) {
      this.formTarget.submit();
    } else {
      this.formTarget.requestSubmit();
    }
  }

  formatReferenceRatio(e) {
    let ratio = 0.05;

    if (e.target.value) {
      ratio = parseFloat(e.target.value);
    }

    if (ratio < 0 || ratio > 0.5) {
      ratio = 0.05
    }

    e.target.value = ratio.toFixed(2);
    this.calReferenceRatio();
  }

  calReferenceRatio() {
    if (this.hasReferenceRevenueRatioTarget) {
      const referenceRevenueRatio = 
        this.articleReferenceRevenueRatioTargets
          .filter(
            target => window.getComputedStyle(target.closest('.nested-form-wrapper')).display !== "none" 
          ).map(
            target => { 
              return parseFloat(target.value)
            }
          ).reduce(
            (prev, cur) => {
              return prev + cur;
            }, 0)
      if (referenceRevenueRatio <= 0.5) {
        this.referenceRevenueRatioTarget.value = parseFloat(referenceRevenueRatio.toFixed(2));
        this.authorRevenueRatioTarget.value = parseFloat((0.5 - referenceRevenueRatio).toFixed(2));
      }
    }
  }

  articleReferenceRevenueRatioTargetConnected() {
    this.calReferenceRatio();
  }

  articleReferenceRevenueRatioTargetDisconnected() {
    this.calReferenceRatio();
  }

  edit() {
    this.activeContentForm();
    this.hidePreview();
    this.hideSettingsForm();
    this.activeTabValue = 'edit';
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
      this.activeTabValue = 'preview';
    });
  }

  options() {
    this.activeSettingsForm();
    this.hideContentForm();
    this.hidePreview();
    this.activeTabValue = 'options';
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
    if (this.hasOptionFieldsTarget && this.hasOptionsButtonTarget) {
      this.optionFieldsTarget.classList.remove("hidden");
      this.optionsButtonTarget.classList.add("border-b-2");
    }
  }

  hideSettingsForm() {
    if (this.hasOptionFieldsTarget && this.hasOptionsButtonTarget) {
      this.optionFieldsTarget.classList.add("hidden");
      this.optionsButtonTarget.classList.remove("border-b-2");
     }
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