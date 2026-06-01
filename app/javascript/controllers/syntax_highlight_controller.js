import { Controller } from "@hotwired/stimulus";
import { highlightCode } from "@37signals/lexxy";

export default class extends Controller {
  connect() {
    highlightCode();
  }
}
