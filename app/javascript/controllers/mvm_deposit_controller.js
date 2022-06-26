import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';

export default class extends Controller {
  static targets = ['qrcode'];

  selectCurrency(event) {
    const asset_id = event.target.value;
    console.log(asset_id);
    get(`/dashboard/destination?asset_id=${asset_id}`, {
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    });
  }
}
