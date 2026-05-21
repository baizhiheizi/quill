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
    updatedAt: Number,
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
    'readersRevenueRatio',
    'authorRevenueRatio',
    'collectionRevenueRatio',
    'referenceRevenueRatio',
    'articleReferenceRevenueRatio',
    'introCharacterCounter',
    'currencyIcon',
    'currencyChainIcon',
    'currencySymbol',
    'priceUsd',
    'publishButton',
    'notSavedAlert',
  ];

  initialize() {
    this.autosave = this.autosave.bind(this);
    this.submit = this.submit.bind(this);

    this.autosave = debounce(this.autosave, 1000);
    this.submit = debounce(this.submit, 1000);
  }

  connect() {
    if (this.newRecordValue) {
      this.showContentForm();
      this.hideOptionFieldsForNewRecord();
    }

    if (this.articlePublishedValue) return;

    const modal = document.querySelector('#modal');
    if (!modal) return;

    modal.addEventListener('modal-component:ok', (event) => {
      const identifier = event.detail.identifier;

      if (identifier !== this.articleUuidValue) return;
      if (
        !this.hasCurrencyIconTarget ||
        !this.hasCurrencyChainIconTarget ||
        !this.hasCurrencySymbolTarget
      ) {
        return;
      }

      const assetSelect = this.element.querySelector('#article_asset_id');
      if (assetSelect) {
        Array.from(assetSelect.children).forEach((option) => {
          option.selected = option.value === event.detail.assetId;
        });
      }

      this.currencyIconTarget.src = event.detail.iconUrl;
      this.currencyChainIconTarget.src = event.detail.chainIconUrl;
      this.currencySymbolTarget.innerText = event.detail.symbol;
      this.currencyPriceUsdValue = event.detail.priceUsd;
      this.touchDirty();
    });
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
    if (this.newRecordValue || this.activeTabValue !== 'options') {
      this.edit();
    } else {
      this.options();
    }

    this.recoverDraftWhenReady();
  }

  contentTargetConnected() {
    this.recoverDraftWhenReady();
  }

  recoverDraftWhenReady() {
    if (!this.hasContentTarget) return;

    this.recoverDraft();
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
    if (this.articlePublishedValue) return;
    this.selectedCollectionIdValue = event.currentTarget.value;
  }

  selectedCollectionIdValueChanged() {
    if (this.articlePublishedValue || !this.hasCollectionRevenueRatioTarget)
      return;

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
    if (!this.currencyPriceUsdValue || !this.hasPriceUsdTarget) return;
    this.calPriceUsd();
  }

  calPriceUsd() {
    if (!this.currencyPriceUsdValue || !this.hasPriceUsdTarget) return;

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

  updateReadersRevenueRatio(event) {
    if (!this.hasReadersRevenueRatioTarget) return;

    if (parseFloat(event.target.value) < 0.1) {
      this.readersRevenueRatioTarget.value = 0.1;
    } else if (parseFloat(event.target.value) > 0.9) {
      this.readersRevenueRatioTarget.value = 0.9;
    } else if (!event.target.value) {
      this.readersRevenueRatioTarget.value = 0.4;
    }
    this.calReferenceRatio();
  }

  formatReferenceRatio(event) {
    if (!this.hasReadersRevenueRatioTarget) return;

    let ratio = 0.05;

    if (event.target.value) {
      ratio = parseFloat(event.target.value);
    }

    if (
      ratio < 0 ||
      ratio > 0.9 - parseFloat(this.readersRevenueRatioTarget.value)
    ) {
      ratio = 0.05;
    }

    event.target.value = ratio.toFixed(2);
    this.calReferenceRatio();
  }

  calReferenceRatio() {
    if (
      !this.hasReferenceRevenueRatioTarget ||
      !this.hasReadersRevenueRatioTarget
    ) {
      return;
    }

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
    if (
      referenceRevenueRatio <=
      0.9 - parseFloat(this.readersRevenueRatioTarget.value)
    ) {
      this.referenceRevenueRatioTarget.value = parseFloat(
        referenceRevenueRatio.toFixed(2),
      );
    }
    this.calAuthorRevenueRatio();
  }

  calAuthorRevenueRatio() {
    if (
      !this.hasAuthorRevenueRatioTarget ||
      !this.hasReadersRevenueRatioTarget ||
      !this.hasReferenceRevenueRatioTarget ||
      !this.hasCollectionRevenueRatioTarget
    ) {
      return;
    }

    this.authorRevenueRatioTarget.value = parseFloat(
      (
        0.9 -
        this.readersRevenueRatioTarget.value -
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
    if (this.newRecordValue) return;

    this.activeSettingsForm();
    this.hideContentForm();
    this.activeTabValue = 'options';
  }

  activeContentForm() {
    this.showContentForm();
    if (this.hasEditButtonTarget) {
      this.editButtonTarget.classList.add('text-primary');
      this.editButtonTarget.classList.remove('opacity-60');
    }
  }

  showContentForm() {
    if (!this.hasContentFieldsTarget) return;

    this.contentFieldsTarget.classList.remove('hidden');
  }

  hideContentForm() {
    if (this.newRecordValue || !this.hasContentFieldsTarget) return;

    this.contentFieldsTarget.classList.add('hidden');
    if (this.hasEditButtonTarget) {
      this.editButtonTarget.classList.remove('text-primary');
      this.editButtonTarget.classList.add('opacity-60');
    }
  }

  activeSettingsForm() {
    if (this.hasOptionFieldsTarget && this.hasOptionsButtonTarget) {
      this.optionFieldsTarget.classList.remove('hidden');
      this.optionsButtonTarget.classList.add('text-primary');
      this.optionsButtonTarget.classList.remove('opacity-60');
    }
  }

  hideSettingsForm() {
    if (this.hasOptionFieldsTarget && this.hasOptionsButtonTarget) {
      this.optionFieldsTarget.classList.add('hidden');
      this.optionsButtonTarget.classList.remove('text-primary');
      this.optionsButtonTarget.classList.add('opacity-60');
    }
  }

  hideOptionFieldsForNewRecord() {
    if (!this.hasOptionFieldsTarget) return;

    this.optionFieldsTarget.classList.add('hidden');
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
    const intro = this.element.querySelector('#article_intro')?.value;
    const content = this.contentValue;

    if (this.autosaveUrlValue) {
      put(this.autosaveUrlValue, {
        body: {
          title,
          intro,
          content,
        },
        contentType: 'application/json',
        responseKind: 'turbo_stream',
      })
        .then(() => {
          if (this.hasNotSavedAlertTarget) {
            this.notSavedAlertTarget.classList.add('hidden');
          }
          this.clearDraft();
        })
        .catch(() => {
          if (this.hasNotSavedAlertTarget) {
            this.notSavedAlertTarget.classList.remove('hidden');
          }

          localStorage.setItem(
            this.draftKeyValue,
            JSON.stringify({ title, intro, content, updatedAt: Date.now() }),
          );

          setTimeout(this.autosave(), 2000);
        });
    } else {
      localStorage.setItem(
        this.draftKeyValue,
        JSON.stringify({ title, intro, content }),
      );
    }
  }

  recoverDraft() {
    const draft = localStorage.getItem(this.draftKeyValue);
    if (!draft) return;

    const { title, intro, content, updatedAt } = JSON.parse(draft);
    if (this.updatedAtValue && this.updatedAtValue > updatedAt) {
      return;
    }

    this.element.querySelector('#article_title').value = title;
    const introElement = this.element.querySelector('#article_intro');
    if (introElement && intro) {
      introElement.value = intro;
      introElement.style.height = '';
      introElement.style.height = introElement.scrollHeight + 'px';
    }
    this.setContentValue(content);
    if (this.hasNotSavedAlertTarget) {
      this.notSavedAlertTarget.classList.remove('hidden');
    }
  }

  get contentValue() {
    if (!this.hasContentTarget) return '';

    const target = this.contentTarget;

    if (target.tagName === 'LEXXY-EDITOR') {
      return target.value ?? '';
    }

    if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') {
      return target.value;
    }

    const hiddenInput = target.querySelector('input[name="article[content]"]');
    if (hiddenInput) return hiddenInput.value;

    return target.value ?? target.textContent ?? '';
  }

  setContentValue(content) {
    if (!this.hasContentTarget) return;

    const target = this.contentTarget;
    const editor =
      target.tagName === 'LEXXY-EDITOR'
        ? target
        : this.contentFieldsTarget?.querySelector('lexxy-editor');

    if (editor) {
      editor.value = content;
      return;
    }

    const hiddenInput =
      target.tagName === 'INPUT'
        ? target
        : target.querySelector('input[name="article[content]"]');

    if (hiddenInput) hiddenInput.value = content;
  }

  clearDraft() {
    localStorage.removeItem(this.draftKeyValue);
  }

  introUpdate(e) {
    if (!this.hasIntroCharacterCounterTarget) return;

    this.introCharacterCounterTarget.innerHTML =
      140 - e.currentTarget.value.length;
  }
}
