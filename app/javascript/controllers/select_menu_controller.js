import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
  }

  selected(e) {
    const path = e.target.value;
    if (path) {
      Turbo.visit(path);
    }
  }
}
