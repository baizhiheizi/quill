import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";

export default class extends Controller {
  static targets = ["scrollArea", "pagination"];

  connect() {
    this.loading = false;
    this.lastFetchedHref = null;
    this.createObserver();
  }

  createObserver() {
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersect(entries),
      {
        // https://github.com/w3c/IntersectionObserver/issues/124#issuecomment-476026505
        threshold: [0, 1.0],
      },
    );
    if (this.hasScrollAreaTarget) {
      this.observer.observe(this.scrollAreaTarget);
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
      this.observer = null;
    }
  }

  handleIntersect(entries) {
    const visible = entries.some((entry) => entry.isIntersecting);
    if (visible) {
      this.loadMore();
    }
  }

  async loadMore() {
    if (this.loading) return;

    const next = this.paginationTarget.querySelector("a");
    if (!next || !next.href) return;

    if (this.lastFetchedHref === next.href) return;

    this.loading = true;
    this.lastFetchedHref = next.href;
    try {
      await get(next.href, {
        contentType: "application/json",
        responseKind: "turbo-stream",
      });
    } finally {
      this.loading = false;
    }
  }
}
