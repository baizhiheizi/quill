import { Controller } from '@hotwired/stimulus';
import { DirectUpload } from '@rails/activestorage';
import { post, put } from '@rails/request.js';
import EasyMDE from 'easymde';
import { showLoading, hideLoading } from '../utils';
import { debounce } from 'underscore';

export default class extends Controller {
  static values = {
    autosaveUrl: String,
    articleUuid: String,
    newRecord: Boolean,
    activeTab: String,
    articlePublished: Boolean,
  };
  static targets = [
    'form',
    'contentFields',
    'optionFields',
    'title',
    'content',
    'images',
    'preview',
    'editButton',
    'previewButton',
    'optionsButton',
    'authorRevenueRatio',
    'referenceRevenueRatio',
    'articleReferenceRevenueRatio',
    'currencyIcon',
    'currencyChainIcon',
    'currencySymbol',
  ];

  initialize() {
    this.autosave = this.autosave.bind(this);
    this.submit = this.submit.bind(this);
  }

  connect() {
    if (this.hasImagesTarget) {
      this.directUploadUrl = this.imagesTarget.dataset.directUploadUrl;
      this.directUploadToken = this.imagesTarget.dataset.directUploadToken;
      this.directUploadAttachmentName =
        this.imagesTarget.dataset.directUploadAttachmentName;
    }

    this.autosave = debounce(this.autosave, 1000);
    this.submit = debounce(this.submit, 1000);

    if (!this.articlePublishedValue) {
      document
        .querySelector('#modal-slot')
        .addEventListener('modal:ok', (event) => {
          const identifier = event.detail.identifier;

          if (identifier === this.articleUuidValue) {
            Array.from(
              this.element.querySelector('#article_asset_id').children,
            ).forEach((option) => {
              if (option.value === event.detail.assetId) {
                option.selected = true;
              } else {
                option.selected = false;
              }
            });
            this.currencyIconTarget.src = event.detail.iconUrl;
            this.currencyChainIconTarget.src = event.detail.chainIconUrl;
            this.currencySymbolTarget.innerText = event.detail.symbol;
            this.submit();
          }
        });
    }
  }

  formTargetConnected() {
    this.initMdEditor();
    switch (this.activeTabValue) {
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

    if (this.newRecordValue) {
      this.recoverDraft();
    }
    this.editor.codemirror.on('change', this.autosave);
  }

  initMdEditor() {
    this.editor = new EasyMDE({
      element: this.contentTarget,
      placeholder: this.contentTarget.placeholder,
      initialValue: this.contentTarget.textContent,
      status: false,
      spellChecker: false,
      sideBySideFullscreen: false,
      syncSideBySidePreviewScroll: false,
      uploadImage: true,
      imageAccept: 'image/png,image/jpeg,image/webp,image/svg',
      imageUploadFunction: (file, onSuccess, onError) => {
        if (file.size > 1024 * 1024 * 5) {
          onError('Image must not larger than 5M');
          return;
        }

        const upload = new DirectUpload(
          file,
          this.directUploadUrl,
          this.directUploadToken,
          this.directUploadAttachmentName,
        );
        showLoading();
        upload.create((error, blob) => {
          hideLoading();
          if (error) {
            onError(error);
          } else {
            onSuccess(`blob://${blob.key}/${blob.filename}`);
          }
        });
      },
      toolbar: [
        'bold',
        'italic',
        'heading-2',
        'heading-3',
        '|',
        'code',
        'quote',
        '|',
        'link',
        'upload-image',
        '|',
        'guide',
      ],
    });
  }

  submit() {
    showLoading();
    if (this.newRecordValue) {
      this.formTarget.submit();
      this.clearDraft();
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
      ratio = 0.05;
    }

    e.target.value = ratio.toFixed(2);
    this.calReferenceRatio();
    this.submit();
  }

  calReferenceRatio() {
    if (this.hasReferenceRevenueRatioTarget) {
      const referenceRevenueRatio = this.articleReferenceRevenueRatioTargets
        .filter(
          (target) =>
            window.getComputedStyle(target.closest('.nested-form-wrapper'))
              .display !== 'none',
        )
        .map((target) => {
          return parseFloat(target.value);
        })
        .reduce((prev, cur) => {
          return prev + cur;
        }, 0);
      if (referenceRevenueRatio <= 0.5) {
        this.referenceRevenueRatioTarget.value = parseFloat(
          referenceRevenueRatio.toFixed(2),
        );
        this.authorRevenueRatioTarget.value = parseFloat(
          (0.5 - referenceRevenueRatio).toFixed(2),
        );
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
    post('/articles/preview', {
      body: JSON.stringify({ content }),
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    }).then(() => {
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
    this.contentFieldsTarget.classList.remove('hidden');
    this.editButtonTarget.classList.add('border-b-2');
  }

  hideContentForm() {
    this.contentFieldsTarget.classList.add('hidden');
    this.editButtonTarget.classList.remove('border-b-2');
  }

  activeSettingsForm() {
    if (this.hasOptionFieldsTarget && this.hasOptionsButtonTarget) {
      this.optionFieldsTarget.classList.remove('hidden');
      this.optionsButtonTarget.classList.add('border-b-2');
    }
  }

  hideSettingsForm() {
    if (this.hasOptionFieldsTarget && this.hasOptionsButtonTarget) {
      this.optionFieldsTarget.classList.add('hidden');
      this.optionsButtonTarget.classList.remove('border-b-2');
    }
  }

  activePreview() {
    this.previewButtonTarget.classList.add('border-b-2');
    this.previewTarget.classList.remove('hidden');
  }

  hidePreview() {
    this.previewButtonTarget.classList.remove('border-b-2');
    this.previewTarget.classList.add('hidden');
    this.previewTarget.classList.innerHTML = '';
  }

  autosave() {
    const title = this.element.querySelector('#article_title').value;
    const content = this.editor.value();

    if (this.autosaveUrlValue) {
      put(this.autosaveUrlValue, {
        body: {
          title,
          content,
        },
        contentType: 'application/json',
        responseKind: 'turbo-stream',
      });
    } else {
      localStorage.setItem(this.draftKey, JSON.stringify({ title, content }));
    }
  }

  recoverDraft() {
    const draft = localStorage.getItem(this.draftKey);
    if (!draft) return;

    const { title, content } = JSON.parse(draft);
    this.element.querySelector('#article_title').value = title;
    this.editor.value(content);
  }

  clearDraft() {
    localStorage.removeItem(this.draftKey);
  }

  get draftKey() {
    return 'prsdigg_article_draft';
  }
}
