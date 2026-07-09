import { Controller } from "@hotwired/stimulus";

// Sibling of `article-form` on the same editor root. Owns revenue-split
// calculation, summary rendering, and validation. Signals the orchestrator that
// the form is dirty by dispatching `queue-autosave` (listened for by
// article_form_controller), keeping the dependency one-way: revenue -> form.
export default class extends Controller {
  static values = {
    selectableCollections: Array,
    selectedCollectionId: String,
    articlePublished: Boolean,
  };

  static targets = [
    "readersRevenueRatio",
    "authorRevenueRatio",
    "collectionRevenueRatio",
    "referenceRevenueRatio",
    "articleReferenceRevenueRatio",
    "revenueSummary",
    "revenueAdvanced",
  ];

  connect() {
    if (this.hasRevenueSummaryTarget) {
      this.renderRevenueSummary();
    }
  }

  selectCollection(event) {
    if (this.articlePublishedValue) return;
    this.selectedCollectionIdValue = event.currentTarget.value;
    this.queueAutosave();
  }

  selectedCollectionIdValueChanged() {
    if (this.articlePublishedValue || !this.hasCollectionRevenueRatioTarget)
      return;

    const selectedCollection = this.selectableCollectionsValue.find(
      (c) => c.uuid == this.selectedCollectionIdValue,
    );
    this.collectionRevenueRatioTarget.value = selectedCollection
      ? selectedCollection.revenue_ratio
      : 0.0;
    this.calReferenceRatio();
  }

  updateReadersRevenueRatio(event) {
    if (!this.hasReadersRevenueRatioTarget) return;

    let value = parseFloat(event.target.value);
    if (Number.isNaN(value) || value < 0.1) value = 0.1;
    if (value > 0.9) value = 0.9;
    this.readersRevenueRatioTarget.value = value;
    this.calReferenceRatio();
    this.queueAutosave();
  }

  formatReferenceRatio(event) {
    if (!this.hasReadersRevenueRatioTarget) return;

    let ratio = 0.05;
    if (event.target.value) ratio = parseFloat(event.target.value);

    if (
      ratio < 0 ||
      ratio > 0.9 - parseFloat(this.readersRevenueRatioTarget.value)
    ) {
      ratio = 0.05;
    }

    event.target.value = ratio.toFixed(2);
    this.calReferenceRatio();
    this.queueAutosave();
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
          window.getComputedStyle(target.closest(".nested-form-wrapper"))
            .display !== "none",
      )
      .map((target) => parseFloat(target.value))
      .reduce((prev, cur) => prev + cur, 0);

    if (
      referenceRevenueRatio <=
      0.9 - parseFloat(this.readersRevenueRatioTarget.value)
    ) {
      this.referenceRevenueRatioTarget.value = parseFloat(
        referenceRevenueRatio.toFixed(2),
      );
    }
    this.calAuthorRevenueRatio();
    this.renderRevenueSummary();
    this.validateRevenueSplit();
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
    this.renderRevenueSummary();
    this.validateRevenueSplit();
  }

  articleReferenceRevenueRatioTargetConnected() {
    this.calReferenceRatio();
  }

  articleReferenceRevenueRatioTargetDisconnected() {
    this.calReferenceRatio();
  }

  toggleRevenueAdvanced(event) {
    event.preventDefault();
    if (!this.hasRevenueAdvancedTarget) return;
    this.revenueAdvancedTarget.classList.toggle("hidden");
  }

  renderRevenueSummary() {
    if (!this.hasRevenueSummaryTarget) return;

    const author = this.hasAuthorRevenueRatioTarget
      ? parseFloat(this.authorRevenueRatioTarget.value)
      : 0;
    const readers = this.hasReadersRevenueRatioTarget
      ? parseFloat(this.readersRevenueRatioTarget.value)
      : 0;
    const platform = 0.1;
    const collection = this.hasCollectionRevenueRatioTarget
      ? parseFloat(this.collectionRevenueRatioTarget.value)
      : 0;
    const references = this.hasReferenceRevenueRatioTarget
      ? parseFloat(this.referenceRevenueRatioTarget.value)
      : 0;

    this.revenueSummaryTarget.innerHTML = this.revenueSummaryTemplate(
      author,
      readers,
      platform,
      collection,
      references,
    );
  }

  revenueSummaryTemplate(author, readers, platform, collection, references) {
    const pct = (value) => `${Math.round(value * 100)}%`;
    const parts = [
      `<span class="font-medium">${pct(author)}</span> you`,
      `<span>${pct(readers)}</span> early readers`,
      `<span>${pct(platform)}</span> platform`,
    ];
    if (collection > 0)
      parts.push(`<span>${pct(collection)}</span> collection`);
    if (references > 0)
      parts.push(`<span>${pct(references)}</span> references`);

    return parts.join(" · ");
  }

  validateRevenueSplit() {
    const sum =
      0.1 +
      (this.hasReadersRevenueRatioTarget
        ? parseFloat(this.readersRevenueRatioTarget.value)
        : 0) +
      (this.hasAuthorRevenueRatioTarget
        ? parseFloat(this.authorRevenueRatioTarget.value)
        : 0) +
      (this.hasCollectionRevenueRatioTarget
        ? parseFloat(this.collectionRevenueRatioTarget.value)
        : 0) +
      (this.hasReferenceRevenueRatioTarget
        ? parseFloat(this.referenceRevenueRatioTarget.value)
        : 0);

    const valid = Math.abs(sum - 1.0) < 0.01;
    if (this.hasRevenueSummaryTarget) {
      this.revenueSummaryTarget.classList.toggle("text-error", !valid);
    }
    return valid;
  }

  // Ask the article-form orchestrator to debounce an autosave. Dispatched as a
  // Stimulus custom event (article-revenue:queue-autosave) on the shared root.
  queueAutosave() {
    this.dispatch("queue-autosave");
  }
}
