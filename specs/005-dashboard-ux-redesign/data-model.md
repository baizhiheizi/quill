# Phase 1 Data Model: Dashboard UI/UX Redesign — From Zero

No database schema changes. Every entity below is a **presentation/navigation-layer concept** composed from existing ActiveRecord models (`User`, `Article`, `Collection`, `Comment`, `Order`, `Payment`, `Transfer`, `Notification`, `AccessToken`, `NotificationSetting`) — none of them are persisted; they exist only as controller/view-layer groupings. This document defines their shape so `/speckit-tasks` can generate concrete, consistent implementation tasks.

## Dashboard Navigation Structure

The redesigned information architecture. Not a database entity — a static, code-defined structure (e.g., a constant/config consumed by the new rail partial and `Dashboard::BaseController`).

| Attribute | Description |
|---|---|
| `sections` | Ordered list of top-level groups: Overview, Write, Read, Finances, Account (5), plus Notifications as a persistent icon (not a 6th section) |
| `active_section` | Set by each controller (e.g., via a `before_action` in `Dashboard::BaseController` or per-controller `@active_section`), drives the rail's current-location highlighting (FR-005) |
| `active_page` / `active_subsection` | Finer-grained than `active_section` where a section has sub-tabs (e.g., Write → Published vs. Drafted) |
| Reachability invariant | Every route under `Dashboard::` MUST map to exactly one `active_section` (FR-002); enforced by a controller test enumerating all dashboard routes at implementation time |

## Dashboard Overview

The new `dashboard#index` landing view's content model. Composed entirely from existing `Users::Statable` methods and small recency queries — no new persisted attributes.

| Field | Source | Notes |
|---|---|---|
| `unread_notifications_count` | `current_user.unread_notifications_count` (`Users::Statable`, already exists) | Powers FR-008's notification indicator |
| `author_revenue_total_usd` | `current_user.author_revenue_total_usd` (`Users::Statable`, already exists) | Shown only when `articles_count > 0` (author-relevant, FR-009) |
| `reader_revenue_total_usd` | `current_user.reader_revenue_total_usd` (`Users::Statable`, already exists) | Shown to every user with reader activity (early-reader reward snapshot) |
| `recent_articles` | `current_user.articles.published.order(updated_at: :desc).limit(3).includes(:currency, :tags, cover_attachment: :blob)` | Author-relevant recent activity (FR-008); empty relation renders the empty state (FR-011) |
| `recent_reads` | `current_user.bought_articles.order(created_at: :desc).limit(3).includes(:author, :currency)` | Reader-relevant recent activity (FR-008) |
| `is_author` | `current_user.articles_count > 0` (counter cache, O(1)) | Drives which role-specific blocks render (FR-009) — not a new column, a derived boolean |
| Quick actions | Static list: "Write" (`new_article_path`), "View earnings" (Finances section), "Notifications" (notifications center) | FR-010 |

## Author Workspace ("Write" section)

Consolidates existing `Dashboard::Articles`, `Dashboard::PublishedArticles`, `Dashboard::DeletedArticles`, `Dashboard::Collections`, `Dashboard::HiddenCollections`, `Dashboard::ListedCollections`, and the author-role slice of `Dashboard::Transfers` under one workspace.

| Sub-area | Backing controller(s) (unchanged) | View change |
|---|---|---|
| Drafted articles | `Dashboard::ArticlesController#index(tab: "drafted")` | Grouped as a labeled status section, not a tab-strip entry (FR-012) |
| Published articles | `Dashboard::ArticlesController#index(tab: "published")`, `Dashboard::PublishedArticlesController` (publish/hide actions) | Per-article actions inline (FR-013) |
| Hidden articles | `Dashboard::ArticlesController#index(tab: "hidden")`, `Dashboard::DeletedArticlesController` | Grouped status section |
| Collections | `Dashboard::CollectionsController` (full CRUD), `Dashboard::{Hidden,Listed}CollectionsController` | Embedded sub-area, not a separate top-level destination |
| Author earnings | `Dashboard::TransfersController#index(tab: "author")` | Embedded earnings sub-area within the workspace (FR-015) |

## Reading Library ("Read" section)

Consolidates `Dashboard::Comments`, `Dashboard::Subscriptions`, `Dashboard::SubscribeArticles`, `Dashboard::SubscribeTags`, `Dashboard::SubscribeUsers`, `Dashboard::Articles#index(tab: "bought")`, and the reader-role slice of `Dashboard::Transfers`.

| Sub-area | Backing controller(s) (unchanged) | View change |
|---|---|---|
| Bought articles | `Dashboard::ArticlesController#index(tab: "bought")` | Purchase/read date shown per FR-016 |
| My comments | `Dashboard::CommentsController` | Embedded sub-area, linkable back to source article |
| Subscriptions (authors/tags/comments) | `Dashboard::Subscriptions`, `Dashboard::SubscribeUsers/Tags/Articles` | Each type its own clearly-labeled sub-area (FR-016), unsubscribe action inline (FR-017) — **blocked users moves out of this group into Account** (see Research §4) |
| Reader rewards | `Dashboard::TransfersController#index(tab: "reader")` | Embedded earnings sub-area (FR-018) |

## Financial View ("Finances" section)

Consolidates `Dashboard::Orders`, `Dashboard::Payments`, and a unified presentation of `Dashboard::Transfers` (both roles in one place, distinguished, not two separate tab contexts spread across Write/Read).

| Field/sub-area | Source | Notes |
|---|---|---|
| Payments (spending) | `current_user.payments` (`Dashboard::PaymentsController`) | FR-019 spending category |
| Orders (per-article drill-down) | `current_user.articles.find(...).orders` (`Dashboard::OrdersController`) | Traceable to source article (FR-020) |
| Reader-reward transfers | `current_user.reader_revenue_transfers` | Clearly attributed to "reader" role (FR-021) |
| Author-revenue transfers | `current_user.author_revenue_transfers` | Clearly attributed to "author" role (FR-021); both roles viewable together for users with both kinds of activity (FR-021) |
| Traceability | `Transfer#source` (polymorphic → `Order` → `Article`/`Collection`) already preloaded via `.includes(:currency, source: { item: :author })` in `Dashboard::TransfersController` | Every row already carries enough data for FR-020 without new queries |

## Notifications Center

Consolidates `Dashboard::Notifications`, `Dashboard::ReadNotifications`, `Dashboard::DeletedNotifications`, `Dashboard::NotificationSettings` — no behavior change, only reachable via a persistent icon (Research §4) instead of a rail group.

| Field | Source | Notes |
|---|---|---|
| Notification list, read/unread state | `current_user.notifications` (Noticed 3, existing) | Unchanged (FR-022) |
| Notification-type preferences | `current_user.notification_setting` (`Dashboard::NotificationSettingsController`, existing) | Embedded within the same center (FR-024), not a separate destination |

## Account Area

Consolidates `Dashboard::ProfileSettings`, `Dashboard::NotificationSettings` (preferences link surfaced from here too), `Dashboard::BlockUsers`, `Dashboard::AccessTokens`, plus the existing locale/theme controls (`edit_locale_path`, `darkmode` Stimulus controller — both already exist and are reused as-is).

| Sub-area | Backing controller(s) (unchanged) | View change |
|---|---|---|
| Profile | `Dashboard::ProfileSettingsController` | Embedded sub-area (FR-025) |
| Blocked users | `Dashboard::BlockUsersController` | **Moved here from "My Subscriptions"** (Research §4) |
| Access tokens | `Dashboard::AccessTokensController` | **Newly linked** — closes the current zero-entry-point gap (FR-003, FR-025) |
| Language / theme | Existing `edit_locale_path` modal, `darkmode` Stimulus controller | Reused, just relocated into Account's nav entry (FR-025) |

## Route Redirect Map (for FR-030 / SC-008)

Old path → new equivalent. Finalized exact new paths are an implementation decision for `/speckit-tasks`; this table records the *coverage requirement* (every old path must map to something), not the final URLs.

| Old path (must keep resolving) | Old param shape | Redirect target section |
|---|---|---|
| `dashboard_root_path` (`dashboard#index`) | — | No redirect needed — becomes the new Overview itself |
| `dashboard_readings_path(tab: :bought\|:comments\|:subscriptions\|:orders\|:transfers)` | `tab` query param | Read section, mapped sub-tab |
| `dashboard_authorings_path(tab: :drafted\|:collections\|:published\|:hidden\|:transfers)` | `tab` query param | Write section, mapped sub-tab |
| `dashboard_settings_path(tab: :profile\|:notification)` | `tab` query param | Account section, mapped sub-tab |
| `dashboard_stats_path` | — | Absorbed into Overview (or redirected there) |
| `dashboard_articles_path(tab: ...)` | `tab` query param | Write or Read section depending on tab value |
| `dashboard_collections_path`, `dashboard_hidden_collections_path`, `dashboard_listed_collections_path` | — | Write section |
| `dashboard_comments_path` | — | Read section |
| `dashboard_subscriptions_path(tab: ...)`, `dashboard_subscribe_{articles,tags,users}_path` | `tab` query param | Read section (except blocked users → Account) |
| `dashboard_block_users_path` | — | Account section (moved from Read) |
| `dashboard_orders_path`, `dashboard_payments_path`, `dashboard_transfers_path(tab: :author\|:reader)`, `dashboard_transfers_stats_path` | `tab`/`role` query param | Finances section |
| `dashboard_notifications_path`, `dashboard_read_notifications_path`, `dashboard_deleted_notifications_path` | — | Notifications center (unchanged reachability, new entry point) |
| `dashboard_notification_settings_path` (update only) | — | Notifications center or Account (settings link) |
| `dashboard_profile_setting_path`, `email_verify` | — | Account section |
| `dashboard_access_tokens_path` | — | Account section (**new** visible entry point, no redirect needed since it had none before) |
