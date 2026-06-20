Hash: manual
# config/routes/api.rb

`namespace :api, defaults: { format: :json }`:
- `resources :articles, only: %i[index show create], param: :uuid`
- `get "valid_user_filter", to: "valid_users#filter"`
- `root to: "home#index"`
- `match "*path", to: "home#index", via: :all` (catch-all)