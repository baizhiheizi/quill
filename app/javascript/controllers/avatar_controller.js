import { Controller } from "@hotwired/stimulus";
import { colorFromSeed } from "../utils/avatar";

export default class extends Controller {
  static values = {
    seed: String,
  };

  connect() {
    this.element.style.backgroundColor = colorFromSeed(this.seedValue);
  }
}
