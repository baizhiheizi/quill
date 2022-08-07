import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';

export default class extends Controller {
  static values = {
    turboStream: true,
    interval: 3000,
  };

  connect() {
    this.interval = setInterval(() => this.refresh(), this.intervalValue);
  }

  refresh() {
    if (this.turboStreamValue) {
      get(location.pathname, {
        responseKind: 'turbo-stream',
      });
    } else {
      Turbo.visit(location.pathname);
    }
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval);
    }
  }
}
