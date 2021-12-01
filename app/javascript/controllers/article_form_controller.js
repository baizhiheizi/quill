import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    persisted: Boolean
  }
  static targets = ["richText", "title"]

  connect() {
    console.log('connected');
    this.trix = this.richTextTarget.editor;
    this.form = this.element;
    console.log(this.form);
  }
}
