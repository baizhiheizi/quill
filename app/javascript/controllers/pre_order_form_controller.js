import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    type: String,
  };

  static targets = ['type', 'typeInput', 'mixpaySubmitButton', 'submitButton'];

  connect() {
  }

  typeValueChanged() {
    this.typeInputTarget.value = this.typeValue;

    this.typeTargets.forEach((target) => {
      const type = target.dataset.preOrderFormTypeParam;
      if (type === this.typeValue) {
        target.classList.add('border-2', 'border-primary');
        target.classList.remove('border-zinc-200');
        target.querySelector('.checkmark').classList.remove('hidden');
      } else {
        target.classList.remove('border-2', 'border-primary');
        target.classList.add('border-zinc-200');
        target.querySelector('.checkmark').classList.add('hidden');
      }
    });

    if (this.typeValue === 'MixpayPreOrder') {
      this.mixpaySubmitButtonTarget.classList.remove('hidden');
      this.submitButtonTarget.classList.add('hidden');
    } else {
      this.mixpaySubmitButtonTarget.classList.add('hidden');
      this.submitButtonTarget.classList.remove('hidden');
    }
  }

  select(event) {
    const { type } = event.params;
    this.typeValue = type;
  }
}
