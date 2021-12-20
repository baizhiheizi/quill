import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['form', 'content'];

  quote(event) {
    const { content, author, id } = event.params;
    const original_content = this.contentTarget.value;

    this.contentTarget.value = `> @${author}([#${id}](#comment_${id})):
${content.replace(/^/gm, '> ')}

${original_content || ''}`;
    this.contentTarget.scrollIntoView(false);
    this.contentTarget.focus();

    const textareaAutogrowController =
      this.application.getControllerForElementAndIdentifier(
        this.contentTarget,
        'textarea-autogrow',
      );
    textareaAutogrowController?.autogrow();
  }
}
