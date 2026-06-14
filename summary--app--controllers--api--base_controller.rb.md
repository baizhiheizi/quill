size:1751
# API::BaseController summary

Inherits from `ActionController::API`. Includes `API::RenderingHelper` and `Pundit::Authorization`.

- `around_action :with_locale` — forces I18n to `:en` for all API responses.
- `after_action :store_access_token_request` — records `{ip, url, method, at}` on the resolved `AccessToken`.
- Custom errors: `UnauthorizedError`, `UnprocessableEntityError`.
- `rescue_from` handlers for `Pundit::NotAuthorizedError`, `StandardError`, `UnauthorizedError`, `UnprocessableEntityError`, `ActiveRecord::RecordNotFound`/`ActionController::RoutingError`, `RecordInvalid`/`RecordNotSaved`.
- Auth: `current_access_token = AccessToken.kept.find_by(value: request.env["HTTP_X_ACCESS_TOKEN"])`, then `current_user = current_access_token&.user`.
- `pundit_user` returns `current_user`.
