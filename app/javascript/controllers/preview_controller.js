import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  close() {
    window.parent.postMessage("close-preview", window.location.origin);
  }
}
