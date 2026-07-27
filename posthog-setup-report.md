# PostHog post-wizard report

The wizard has completed a deep integration of PostHog analytics into the Quill Ruby on Rails application. The integration covers the full user journey — from OAuth sign-up through content creation, community engagement, and cryptocurrency-based revenue events. Both server-side (posthog-ruby + posthog-rails) and client-side (posthog-js) tracking are in place.

**Changes made:**
- Added `posthog-ruby` and `posthog-rails` gems to `Gemfile` and installed via Bundler
- Created `config/initializers/posthog.rb` with `PostHog.init`, auto-exception capture, ActiveJob instrumentation, and user-context detection via `current_user`
- Added `posthog_distinct_id` (returns `id.to_s`) and `posthog_properties` to `app/models/user.rb`
- Added posthog-js snippet with `posthog.identify` to three layouts: `application.html.erb`, `public.html.erb`, and `editor.html.erb`
- Set `POSTHOG_PROJECT_TOKEN` and `POSTHOG_HOST` in `.env` (covered by `.gitignore`)

## Events instrumented

| Event name | Description | File |
|---|---|---|
| `user_signed_up` | A new user registers for the first time via Mixin or Twitter OAuth. | `app/controllers/oauth/callbacks_controller.rb` |
| `user_logged_in` | An existing user signs in via Mixin or Twitter OAuth. | `app/controllers/oauth/callbacks_controller.rb` |
| `article_created` | An author creates a new article draft. | `app/controllers/articles_controller.rb` |
| `article_published` | An author publishes an article, making it publicly accessible. | `app/controllers/dashboard/published_articles_controller.rb` |
| `article_purchased` | A reader buys a paid article with cryptocurrency. | `app/models/order.rb` |
| `article_rewarded` | A reader sends a cryptocurrency tip/reward to an article's author. | `app/models/order.rb` |
| `collection_purchased` | A reader buys an entire collection (series) of articles. | `app/models/order.rb` |
| `payment_initiated` | A user initiates a MixPay pre-order payment for an article or collection. | `app/controllers/mixpay_pre_orders_controller.rb` |
| `comment_created` | A user posts a comment on an article. | `app/controllers/comments_controller.rb` |
| `article_upvoted` | A user upvotes an article. | `app/controllers/upvoted_articles_controller.rb` |
| `user_subscribed_to_author` | A user subscribes to follow another author's content. | `app/controllers/subscribe_users_controller.rb` |
| `tag_subscribed` | A user subscribes to a topic tag to follow related articles. | `app/controllers/subscribe_tags_controller.rb` |

## Next steps

We've built some insights and a dashboard for you to keep an eye on user behavior, based on the events we just instrumented:

- **Dashboard:** [Analytics basics (wizard)](https://us.posthog.com/project/529635/dashboard/1908871)
- **Insight:** [Payment conversion funnel (wizard)](https://us.posthog.com/project/529635/insights/OlHwPhOD) — Conversion from `payment_initiated` → `article_purchased`
- **Insight:** [New user signups over time (wizard)](https://us.posthog.com/project/529635/insights/UmdAEbGT) — Daily `user_signed_up` bar chart
- **Insight:** [Content publishing pipeline (wizard)](https://us.posthog.com/project/529635/insights/sWglmSDp) — Weekly `article_created` vs `article_published`
- **Insight:** [Community engagement over time (wizard)](https://us.posthog.com/project/529635/insights/PM3ZSdQ2) — Daily comments, upvotes, and subscriptions
- **Insight:** [Revenue events over time (wizard)](https://us.posthog.com/project/529635/insights/7El0QYyz) — Weekly stacked bar of purchases and rewards

## Verify before merging

- [ ] Run a full production build (the wizard only verified the files it touched) and fix any lint or type errors introduced by the generated code.
- [ ] Run the test suite — call sites that were rewritten or instrumented may need updated mocks or fixtures.
- [ ] Add `POSTHOG_PROJECT_TOKEN` and `POSTHOG_HOST` to `.env.example` and any bootstrap scripts so collaborators know what to set.
- [ ] Confirm the returning-visitor path also calls `identify` — the `posthog.identify` in the layouts fires on every page load for logged-in users, which covers returning sessions, but verify this works correctly with Turbo Drive (the posthog-js snippet initialises once; `identify` re-fires on each full-page navigation but not on Turbo frame swaps).
- [ ] This project uses PostgreSQL. Running `npx @posthog/wizard warehouse` will connect the database to PostHog's data warehouse for SQL-level analysis alongside your event data.

### Agent skill

We've left an agent skill folder in your project at `.claude/skills/integration-ruby-on-rails/`. You can use this context for further agent development when using Claude Code. This will help ensure the model provides the most up-to-date approaches for integrating PostHog.
