import { Controller } from '@hotwired/stimulus';
import { debounce } from 'lodash';
import * as Rails from '@rails/ujs';

export default class extends Controller {
  static targets = ["form"];
  static values = {
    delay: Number
  }

  initialize () {
    this.save = this.save.bind(this)
  }

  connect () {
    if (this.delayValue > 0) {
      this.save = debounce(this.save, this.delayValue)
    }
  }

  save () {
    if (!window._rails_loaded) return

    Rails.fire(this.formTarget, 'submit')
  }
}
