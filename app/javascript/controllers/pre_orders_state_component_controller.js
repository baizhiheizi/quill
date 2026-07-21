import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";

export default class extends Controller {
  static values = {
    followId: String,
    interval: 1500,
  };

  connect() {
    this.startPolling();
    this._boundVisibilityChanged = this._visibilityChanged.bind(this);
    document.addEventListener("visibilitychange", this._boundVisibilityChanged);
  }

  _visibilityChanged() {
    if (document.hidden) {
      this.stopPolling();
    } else {
      this.startPolling();
    }
  }

  startPolling() {
    if (this._interval) clearInterval(this._interval);
    this._interval = setInterval(() => this.verify(), this.intervalValue);
  }

  stopPolling() {
    if (this._interval) {
      clearInterval(this._interval);
      this._interval = null;
    }
  }

  verify() {
    if (!this.followIdValue) return;

    get(`/pre_orders/${this.followIdValue}/state`, {
      contentType: "application/json",
    })
      .then((res) => res.json)
      .then(({ redirect_url }) => {
        if (redirect_url) {
          Turbo.visit(redirect_url);
        }
      });
  }

  disconnect() {
    this.stopPolling();
    if (this._boundVisibilityChanged) {
      document.removeEventListener(
        "visibilitychange",
        this._boundVisibilityChanged,
      );
    }
  }
}
