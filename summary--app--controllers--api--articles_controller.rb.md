Hash: manual
# app/controllers/api/articles_controller.rb

`API::ArticlesController < API::BaseController`. JSON-only.

- `index` — picks scope by `params[:author_id]` (author's published articles) → `current_user.articles` → `Article.only_published`. Filters via Ransack OR on title/intro/tags. Orders by `params[:order]` (asc/desc) or `order_by_popularity`. Applies numeric or ISO `offset`. `limit` defaults 20, max 100.
- `show` — `Article.find_by!(uuid:)` then Pundit `ArticlePolicy#show?`.
- `create` — requires token (401 otherwise). `current_user.articles.new(article_params.merge(source: token.value))`. After save: `CreateTagService.call`, `article.publish!` if `may_publish?`. Returns `{ uuid: }` or 422.
- `article_params` — `params.require(:article).permit(:title, :intro, :content, :price, :asset_id)`.