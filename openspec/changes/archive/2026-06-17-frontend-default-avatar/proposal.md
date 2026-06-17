## Why

The default user avatar fallback uses `api.multiavatar.com`, which is no longer available. Users without an uploaded avatar or OAuth profile image see broken images across the site, in notifications, and in API responses. We need a self-contained replacement that does not depend on external avatar-generation services.

## What Changes

- Remove `generated_avatar_url` fallback from `User` (and related models that share the same dead URL pattern)
- Introduce a frontend-only initials + deterministic color placeholder when no real avatar image exists
- Add a shared `shared/_avatar` partial and Stimulus controller to render avatars consistently across ~35 view call sites
- Split avatar URL behavior: web UI uses the partial; server contexts that require a fetchable URL (Mixin bot notifications, share links, Grover posters) fall back to the platform icon asset
- Update JSON API responses to return `null` for avatar when no real image exists, plus seed/name fields for client-side fallback rendering
- Extract shared avatar utility functions for JS consumers (e.g. Tom Select reference picker)

## Capabilities

### New Capabilities

- `user-default-avatar`: Frontend initials + color placeholder for users without a real avatar image; backend returns nil instead of a generated URL; external contexts use static platform icon fallback

### Modified Capabilities

<!-- No existing openspec specs cover avatar behavior -->

## Impact

- **Models**: `User#avatar_url`, `User#avatar_thumb`, `MixinNetworkUser`, `NftCollection`
- **Views**: ~35 ERB call sites using `avatar_url` / `avatar_thumb` directly
- **JavaScript**: New `avatar_controller.js`, shared `utils/avatar.js`; update `references_select_controller.js`
- **API**: `app/views/api/articles/*.json.jbuilder`, `article_references/index.json.jbuilder` — avatar may be null; new fields added
- **Notifiers**: Continue using fetchable URL via external fallback helper (platform icon when no real avatar)
- **Tests**: Notifier tests asserting `avatar_url` in payloads; any controller/view tests depending on multiavatar URLs
- **Dependencies**: None (no new npm gems)
