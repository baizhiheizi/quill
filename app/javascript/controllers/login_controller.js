import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['mixin', 'eth'];

  connect() {}

  showEth() {
    this.mixinTarget.classList.add('hidden');
    this.ethTarget.classList.remove('hidden');
  }

  showMixin() {
    this.mixinTarget.classList.remove('hidden');
    this.ethTarget.classList.add('hidden');
  }
}
