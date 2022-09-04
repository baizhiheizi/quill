import { Controller } from '@hotwired/stimulus';
import { put } from '@rails/request.js';
import { showLoading } from '../utils';
import { debounce } from 'underscore';

export default class extends Controller {
  static values = {
    draftKey: String,
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
    'editButton',
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

    this.autosave = debounce(this.autosave, 1500);
    this.submit = debounce(this.submit, 1500);
  }

  connect() {
    if (!this.articlePublishedValue) {
      document
        .querySelector('#modal')
        .addEventListener('modal-component:ok', (event) => {
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
    switch (this.activeTabValue) {
      case 'edit':
        this.edit();
        break;
      case 'options':
        this.options();
        break;
    }

    if (this.newRecordValue) {
      this.recoverDraft();
    }
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
    this.hideSettingsForm();
    this.activeTabValue = 'edit';
  }

  options() {
    this.activeSettingsForm();
    this.hideContentForm();
    this.activeTabValue = 'options';
  }

  activeContentForm() {
    this.contentFieldsTarget.classList.remove('hidden');
    this.editButtonTarget.classList.add('border-primary');
    this.editButtonTarget.classList.remove(
      'border-white',
      'dark:border-zinc-900',
    );
  }

  hideContentForm() {
    this.contentFieldsTarget.classList.add('hidden');
    this.editButtonTarget.classList.remove('border-primary');
    this.editButtonTarget.classList.add('border-white', 'dark:border-zinc-900');
  }

  activeSettingsForm() {
    if (this.hasOptionFieldsTarget && this.hasOptionsButtonTarget) {
      this.optionFieldsTarget.classList.remove('hidden');
      this.optionsButtonTarget.classList.add('border-primary');
      this.optionsButtonTarget.classList.remove(
        'border-white',
        'dark:border-zinc-900',
      );
    }
  }

  hideSettingsForm() {
    if (this.hasOptionFieldsTarget && this.hasOptionsButtonTarget) {
      this.optionFieldsTarget.classList.add('hidden');
      this.optionsButtonTarget.classList.remove('border-primary');
      this.optionsButtonTarget.classList.add(
        'border-white',
        'dark:border-zinc-900',
      );
    }
  }

  autosave() {
    const title = this.element.querySelector('#article_title').value;
    const content = this.contentTarget.textContent;

    if (this.autosaveUrlValue) {
      put(this.autosaveUrlValue, {
        body: {
          title,
          content,
        },
        contentType: 'application/json',
        responseKind: 'turbo_stream',
      });
    } else {
      localStorage.setItem(
        this.draftKeyValue,
        JSON.stringify({ title, content }),
      );
    }
  }

  recoverDraft() {
    const draft = localStorage.getItem(this.draftKeyValue);
    if (!draft) return;

    const { title, content } = JSON.parse(draft);
    this.element.querySelector('#article_title').value = title;
    this.contentTarget.textContent = content;
  }

  clearDraft() {
    localStorage.removeItem(this.draftKeyValue);
  }
}
