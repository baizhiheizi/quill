import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['button'];
  static values = {
    text: String,
    successTip: String,
    successDuration: {
      type: Number,
      default: 2000,
    },
  };

  connect() {
    if (!this.hasButtonTarget) return;

    this.originalText = this.buttonTarget.innerText;
  }

  copy(event) {
    event.preventDefault();

    if (navigator.clipboard) {
      navigator.clipboard.writeText(this.textValue);
    } else {
      const tempInput = document.createElement("input");
      tempInput.style = "position: absolute; left: -1000px; top: -1000px";
      tempInput.value = this.textValue;
      document.body.appendChild(tempInput);
      tempInput.select();
      document.execCommand("copy");
      document.body.removeChild(tempInput);
    }

    this.copied();
  }

  copied() {
    if (!this.hasButtonTarget) return;

    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    this.buttonTarget.innerText = this.successTipValue;

    this.timeout = setTimeout(() => {
      this.buttonTarget.innerText = this.originalText;
    }, this.successDurationValue);
  }
}
