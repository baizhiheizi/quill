## 1. Frontend avatar utilities

- [x] 1.1 Create `app/javascript/utils/avatar.js` with `initials(name)`, `colorFromSeed(seed)`, and `renderAvatarHtml({ seed, name, className })`
- [x] 1.2 Create `app/javascript/controllers/avatar_controller.js` — sets background color from seed on connect; register in `controllers/index.js`
- [x] 1.3 Add `UserHelper#avatar_initials(name)` for ERB partial (mirror JS initials logic)

## 2. Shared avatar partial

- [x] 2.1 Create `app/views/shared/_avatar.html.erb` — renders `<img>` when real URL exists, else initials placeholder with Stimulus data attributes
- [x] 2.2 Support locals: `user`, `class:` (size/styling), `thumb:` (boolean, default false)

## 3. Backend model changes

- [x] 3.1 Update `User#avatar_image_url` (or refactor `avatar_url`) to return nil when no ActiveStorage/OAuth avatar; remove `generated_avatar_url`
- [x] 3.2 Update `User#avatar_url` to return `avatar_image_url || ActionController::Base.helpers.asset_url('icon.png')` for external/notifier use
- [x] 3.3 Update `User#avatar_thumb` to mirror image-url logic without multiavatar fallback
- [x] 3.4 Remove multiavatar fallback from `MixinNetworkUser#generated_avatar_url`; use platform icon instead
- [x] 3.5 Remove multiavatar fallback from `NftCollection` icon method; use platform icon instead

## 4. View migration

- [x] 4.1 Replace direct `image_tag user.avatar_url` / `avatar_thumb` calls with `render "shared/avatar"` across all ~35 ERB call sites
- [x] 4.2 Preserve existing size classes at each call site via `class:` local

## 5. API and JS consumers

- [x] 5.1 Update `app/views/api/articles/show.json.jbuilder` and `index.json.jbuilder` — add `avatar_seed`, `avatar_initials`; return null avatar when no real image
- [x] 5.2 Update `app/views/article_references/index.json.jbuilder` with same avatar fields
- [x] 5.3 Update `references_select_controller.js` to use `renderAvatarHtml` when avatar is null
- [x] 5.4 Update `article_references/_form.html.erb` JSON options if needed for new fields

## 6. Tests and lint

- [x] 6.1 Add unit tests for `UserHelper#avatar_initials` (Latin, CJK, single word)
- [x] 6.2 Update notifier tests that assert `avatar_url` in payloads
- [x] 6.3 Add model test: user without avatar returns nil from `avatar_image_url`, icon from `avatar_url`
- [x] 6.4 Run `bin/rubocop` on touched Ruby files and `bun run lint-check` on touched JS files
