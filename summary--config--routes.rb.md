<!-- hash: 4100 -->
Root route file. Top-level behaviour:
- 301 redirect for legacy `prsdigg.com` / `bunshow.jp` domains to `quill.im`.
- Mounts four sub-draws: `admin`, `dashboard`, `api`, `grover`.
- Mixin OAuth + Twitter auth (`/auth/mixin/callback`, `/auth/twitter/callback`), login/logout, sessions.
- Public reading: `root`, `hot_tags`, `active_authors`, `selected_articles`, `more`, `search`.
- Locale switcher (`resource :locale`, `/:locale`).
- Collections, articles, comments, upvoted/downvoted, references, block users, subscriptions, tags, currencies, users, pre-orders, transfers, high_voltage pages (fair, rules).
- Two regex-based route tails: `/:uid` → users#show, `/:uid/:uuid` → articles#show (using Mixin UUID or ETH address patterns).
