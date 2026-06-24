<file hash: 2026-06-24-manual</content>
<content>
# app/controllers/admin/comments_controller.rb summary

Admin::CommentsController < Admin::BaseController.
After PR #1721: only `:index`, `:delete`, `:undelete` actions (the unreachable `:show` was removed).

Actions:
- index — list Comments with optional filters (author_id, commentable_id, commentable_type, state [deleted|without_deleted|all], order_by, query via Ransack). Paginates with Pagy.
- delete — soft-delete by comment_id param.
- undelete — soft-undelete by comment_id param.