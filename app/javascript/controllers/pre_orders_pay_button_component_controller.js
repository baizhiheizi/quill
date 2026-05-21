import { mixinContext } from 'mixin-messenger-utils';
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['qrcode'];

  qrcodeTargetConnected() {
    if (mixinContext.platform && mixinContext.platform !== 'Desktop') return;

    this.qrcodeTarget.classList.remove('hidden');
  }
}
