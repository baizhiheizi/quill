<file hash: 2026-06-24-manual</content>
<content>
# config/routes/admin.rb summary

Admin namespace gated by AdminConstraint (session-based, Administrator lookup).

Mounts:
- MissionControl::Jobs::Engine at /admin/jobs
- PgHero::Engine at /admin/pghero
- ExceptionTrack::Engine at /admin/exception-track

Root: overview#index
Login/logout: GET/POST /admin/login, /admin/logout

Resources (all under /admin):
- sessions (index only)
- users (index, show) with validate/unvalidate/block/unblock
- collections (index, show)
- articles (index, show) with block/unblock
- comments (index) with delete/undelete  -- NOTE: show action was removed in PR #1721
- orders (index, show)
- pre_orders (index, show, param: :follow_id)
- swap_orders (index, show)
- payments (index, show)
- transfers (index, show) with process_now
- mixin_network_snapshots (index, show) with process_now
- mixin_network_users (index, show)
- statistics (index)
- bonuses (index, create, new) with deliver
- wallets (full) with assets/snapshots/safe_outputs nested