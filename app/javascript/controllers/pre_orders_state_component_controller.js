import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';

export default class extends Controller {
  static values = {
    followId: String,
    interval: 1500,
  };

  connect() {
    this.interval = setInterval(() => this.verify(), this.intervalValue);
  }

  verify() {
    if (!this.followIdValue) return;

    get(`/pre_orders/${this.followIdValue}/state`, {
      contentType: 'application/json',
    })
      .then((res) => res.json)
      .then(({ redirect_url }) => {
        if (redirect_url) {
          Turbo.visit(redirect_url);
        }
      });
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval);
    }
  }
}
