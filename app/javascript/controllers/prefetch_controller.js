import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  initialize() {
    this.prefetch = this.prefetch.bind(this);
    this.load = this.load.bind(this);
  }

  connect() {
    if (!this.hasPrefetch) return;

    this.element.addEventListener('mouseover', () => {
      this.prefetch();
    });
  }

  load() {
    const observer = new IntersectionObserver((entries, observer) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          this.prefetch();

          observer.unobserve(entry.target);
        }
      });
    });

    observer.observe(this.element);
  }

  prefetch() {
    const connection = navigator.connection;

    if (connection) {
      // Don't prefetch if using 2G or if Save-Data is enabled.
      if (connection.saveData) {
        console.warn(
          '[stimulus-prefetch] Cannot prefetch, Save-Data is enabled.',
        );
        return;
      }

      if (/2g/.test(connection.effectiveType)) {
        console.warn(
          '[stimulus-prefetch] Cannot prefetch, network conditions are poor.',
        );
        return;
      }
    }
    if (document.head.querySelector(`link[href="${this.element.href}"]`)) {
      return;
    }

    const link = document.createElement('link');
    link.rel = 'prefetch';
    link.href = this.element.href;
    link.as = 'document';

    document.head.appendChild(link);
  }

  get hasPrefetch() {
    const link = document.createElement('link');

    return (
      link.relList && link.relList.supports && link.relList.supports('prefetch')
    );
  }
}
