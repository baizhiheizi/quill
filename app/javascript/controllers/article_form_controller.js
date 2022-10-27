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
    currencyPriceUsd: Number,
    dirty: Boolean,
    selectableCollections: Array,
    selectedCollectionId: String,
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
    'collectionRevenueRatio',
    'referenceRevenueRatio',
    'articleReferenceRevenueRatio',
    'currencyIcon',
    'currencyChainIcon',
    'currencySymbol',
    'priceUsd',
    'publishButton',
  ];

  initialize() {
    this.autosave = this.autosave.bind(this);
    this.submit = this.submit.bind(this);

    this.autosave = debounce(this.autosave, 1000);
    this.submit = debounce(this.submit, 1000);
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
            this.currencyPriceUsdValue = event.detail.priceUsd;
            this.touchDirty();
          }
        });
    }
  }

  disconnect() {
    document.removeEventListener('turbo:before-visit', this.confirmLeaving);
  }

  confirmLeaving(event) {
    if (confirm('Article is not saved yet. Are you sure to leave?') == false) {
      event.preventDefault();
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

  dirtyValueChanged() {
    if (!this.hasPublishButtonTarget) return;

    if (this.dirtyValue) {
      this.publishButtonTarget.disabled = true;
      this.publishButtonTarget.classList.add(
        'cursor-not-allowed',
        'opacity-60',
      );
      this.publishButtonTarget.classList.remove('cursor-pointer');
      document.addEventListener('turbo:before-visit', this.confirmLeaving);
    } else {
      this.publishButtonTarget.disabled = false;
      this.publishButtonTarget.classList.remove(
        'cursor-not-allowed',
        'opacity-60',
      );
      this.publishButtonTarget.classList.add('cursor-pointer');
      document.removeEventListener('turbo:before-visit', this.confirmLeaving);
    }
  }

  touchDirty() {
    this.dirtyValue = true;
  }

  selectCollection(event) {
    console.log('selected');
    this.selectedCollectionIdValue = event.currentTarget.value;
  }

  selectedCollectionIdValueChanged() {
    const selectedCollection = this.selectableCollectionsValue.find(
      (c) => c.uuid == this.selectedCollectionIdValue,
    );
    if (selectedCollection) {
      this.collectionRevenueRatioTarget.value =
        selectedCollection.revenue_ratio;
    } else {
      this.collectionRevenueRatioTarget.value = 0.0;
    }
    this.calReferenceRatio();
  }

  currencyPriceUsdValueChanged() {
    if (!this.currencyPriceUsdValue) return;
    this.calPriceUsd();
  }

  calPriceUsd() {
    if (!this.currencyPriceUsdValue) return;

    const priceInput = this.element.querySelector(
      "input[name='article[price]']",
    );
    const price = (priceInput && priceInput.value) || 0;
    this.priceUsdTarget.innerText = (
      parseFloat(price) * parseFloat(this.currencyPriceUsdValue)
    ).toFixed(4);
  }

  submit() {
    if (this.formTarget.checkValidity()) {
      showLoading();
    }
    if (this.newRecordValue) {
      this.formTarget.submit();
      this.clearDraft();
    } else {
      this.formTarget.requestSubmit();
    }
  }

  formatReferenceRatio(event) {
    let ratio = 0.05;

    if (event.target.value) {
      ratio = parseFloat(event.target.value);
    }

    if (ratio < 0 || ratio > 0.5) {
      ratio = 0.05;
    }

    event.target.value = ratio.toFixed(2);
    this.calReferenceRatio();
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
      }
    }
    this.calAuthorRevenueRatio();
  }

  calAuthorRevenueRatio() {
    this.authorRevenueRatioTarget.value = parseFloat(
      (
        0.5 -
        this.referenceRevenueRatioTarget.value -
        this.collectionRevenueRatioTarget.value
      ).toFixed(2),
    );
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

  save() {
    if (this.activeTabValue === 'edit') {
      this.autosave();
    } else {
      this.submit();
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
