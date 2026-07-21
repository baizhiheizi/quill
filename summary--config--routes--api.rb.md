<!-- hash: 270 -->
Routes for API namespace (format: :json):
- resources :articles, only: [:index, :show, :create], param: :uuid
- GET /valid_user_filter → valid_users#filter
- root → home#index
- match *path → home#index (catch-all)