import { Controller } from '@hotwired/stimulus';
import { get } from '@rails/request.js';

export default class extends Controller {
  connect() {
    if (!location.hash) return;

    if (location.hash.match(/#comment_\d+/)) {
      const commentId = location.hash.split('_')[1];
      this.showCommentFormModal(commentId);
    }
  }

  showCommentFormModal(commentId) {
    get(`/comments/new?quote_comment_id=${commentId}`, {
      responseKind: 'turbo-stream',
    });
  }
}
