import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';

export default class extends Controller {
  static targets = ["form"];
  static values = {
    content: String,
    identifier: String,
  };

  initialize() {
    this.ok = this.ok.bind(this);
  }

  connect() {
  }

  invoke(event) {
    event.preventDefault();
    this.show();
  }

  show() {
    document.addEventListener("modal:ok", this.ok);
    post('/view_modals', {
      body: {
        type: 'confirm',
        content: this.contentValue,
        identifier: this.identifierValue
      },
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    })
  }

  ok(event) {
    const identifier = event.detail?.identifier;
    if (identifier === this.identifierValue) {
      if (this.formTarget.requestSubmit) {
        this.formTarget.requestSubmit();
       } else {
        this.formTarget.submit();
       }
      document.removeEventListener("modal:ok", this.ok);
    }
  }
}
