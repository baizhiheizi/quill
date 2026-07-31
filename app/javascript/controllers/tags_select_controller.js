import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";
import TomSelect from "tom-select";

export default class extends Controller {
  static values = {
    items: Array,
  };

  connect() {
    this.select = new TomSelect(this.element, {
      create: true,
      creatFilter: function (input) {
        return input.length >= 2;
      },
      items: this.itemsValue,
      load: (query, callback) => this.loadTagOptions(query, callback),
      maxItems: 10,
    });
  }

  // Destroy the TomSelect instance and detach its listeners so they do
  // not leak when the controller disconnects (e.g. Turbo navigation).
  // Without this, every navigation cycle leaves the wrapper element
  // and its document/window listeners in memory until the page reloads.
  disconnect() {
    if (this.select) {
      this.select.destroy();
      this.select = null;
    }
  }

  loadTagOptions(query, callback) {
    get("/tags?query=" + encodeURIComponent(query), {
      contentType: "application/json",
      responseKind: "json",
    })
      .then((req) => req.response.json())
      .then((options) =>
        callback(
          options.map((option) => {
            return { text: option, value: option };
          }),
        ),
      )
      .catch(() => callback());
  }
}
