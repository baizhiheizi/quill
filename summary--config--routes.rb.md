Hash: manual
# config/routes.rb

Mounts six surfaces via `draw :admin / :dashboard / :mvm / :api / :grover`.

Public routes: login (`/login`), OAuth callbacks (`/auth/mixin`, `/auth/twitter`, `/auth/fennec`, `/auth/mvm`), logout, `/nonce`, `/search`, health (`/up`), error pages (`/404`, `/406`, `/422`, `/500`), root `home#index`, `hot_tags`, `active_authors`, `selected_articles`, `more`, `resource :locale`, locale-prefixed paths (`/:locale`), collections (`/collections/:uuid`), articles (`/articles/:uuid`, `:update_content`, `:share`, comments), voting (`upvoted_articles`, `downvoted_articles`, comments), article references (JSON), `block_users`, subscribe routes, tags, currencies, users (`/users/:uid`, nested), pre-orders (`/pre_orders/:follow_id` with `:state` JSON), `mixpay_pre_order`, transfers + `/transfers/stats`, High Voltage pages (`/fair`, `/rules`), short-form `/users/:uid` and `/users/:uid/articles/:uuid`.

`SubdomainConstraint` 301-redirects requests on `prsdigg.com` / `bunshow.jp` to `quill.im`.