import { Controller } from "@hotwired/stimulus";
import { highlightWithin } from "../utils/highlight";

export default class extends Controller {
  connect() {
    highlightWithin(this.element);
  }
}
