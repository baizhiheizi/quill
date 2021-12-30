import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';

export default class extends Controller {
  static targets = ['scrollArea', 'pagination'];

  connect() {
    this.createObserver();
  }

  createObserver() {
    const observer = new IntersectionObserver(
      (entries) => this.handleIntersect(entries),
      {
        // https://github.com/w3c/IntersectionObserver/issues/124#issuecomment-476026505
        threshold: [0, 1.0],
      },
    );
    observer.observe(this.scrollAreaTarget);
  }

  handleIntersect(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        this.loadMore();
      }
    });
  }

  loadMore() {
    const next = this.paginationTarget.querySelector('a');

    if (next && next.href) {
      get(next.href, {
        contentType: 'application/json',
        responseKind: 'turbo-stream',
      });
    }
  }
}
