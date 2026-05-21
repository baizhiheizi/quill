import { Controller } from '@hotwired/stimulus';
import * as QRCode from 'qrcode';

export default class extends Controller {
  static values = {
    url: String,
  };
  static targets = ['placeholder'];

  connect() {}

  urlValueChanged() {
    this.replacePlaceHolder();
  }

  async replacePlaceHolder() {
    const code = await this.generateQrcode();
    this.placeholderTarget.innerHTML = `<img class="my-0" src="${code}" />`;
  }

  generateQrcode() {
    return QRCode.toDataURL(this.urlValue);
  }
}
