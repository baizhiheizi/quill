import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';

export default class extends Controller {
  connect() {
    if (!location.hash) return;

    if (location.hash.match(/#comment_\d+/)) {
      const commentId = location.hash.split('_')[1];
      this.showCommentFormModal(commentId);
    }
  }

  showCommentFormModal(commentId) {
    post('/view_modals', {
      body: {
        type: 'comment_form',
        quote_comment_id: commentId,
      },
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    });
  }
}
