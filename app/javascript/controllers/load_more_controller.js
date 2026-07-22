import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";

export default class extends Controller {
  fetch(event) {
    const { link } = event.params;

    if (link) {
      get(link, {
        contentType: "application/json",
        responseKind: "turbo-stream",
      });
    }
  }
}
