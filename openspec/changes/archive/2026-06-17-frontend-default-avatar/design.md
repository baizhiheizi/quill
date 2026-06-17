## Context

User avatars resolve through a three-tier chain: ActiveStorage upload → OAuth/Mixin `authorization.avatar_url` → `generated_avatar_url` (dead `api.multiavatar.com` URL keyed by `mixin_uuid`). The same dead URL appears in `MixinNetworkUser` and `NftCollection`.

Approximately 35 ERB views render avatars via raw `image_tag user.avatar_url` / `avatar_thumb` with no shared partial. FlyonUI provides `.avatar` and `.avatar-placeholder` CSS classes already present in the build. The stack uses Stimulus for interactive components and esbuild for bundling.

Server contexts that require a fetchable image URL (Mixin bot notification cards, share-to-Mixin `icon_url`, Grover poster rendering) cannot use a pure CSS/JS placeholder — they need a real HTTP URL.

## Goals / Non-Goals

**Goals:**

- Replace dead Multiavatar fallback with a frontend initials + deterministic color placeholder
- Centralize avatar rendering in a shared partial used across web views
- Return `nil` from backend avatar methods when no real image exists (no synthetic URLs)
- Provide a static platform icon fallback for server/external contexts
- Support CJK and Latin name initials consistently
- Share avatar rendering logic between Stimulus partial and JS consumers (Tom Select)

**Non-Goals:**

- Server-side SVG generation or new avatar API routes
- New npm dependencies (DiceBear, etc.)
- Changing ActiveStorage upload flow or OAuth avatar sync
- Redesigning avatar upload UX in profile settings
- NFT collection icon redesign beyond removing dead Multiavatar URL

## Decisions

### 1. Initials + color over identicon library

**Choice:** Initials with HSL background derived from `mixin_uuid` hash.

**Rationale:** Zero bundle size, familiar UX (GitHub/Slack pattern), accessible (text content), no maintenance of external library styles.

**Alternative considered:** `@dicebear/core` — closer to Multiavatar's illustrated look but adds dependency and bundle weight for marginal benefit.

### 2. Split URL methods: web vs external

**Choice:**

- `avatar_image_url` — returns real URL or `nil` (rename/clarify existing `avatar_url` behavior)
- `avatar_url` — alias that returns `avatar_image_url || asset_url('icon.png')` for backward-compatible external use (notifiers, share, Grover)

**Rationale:** Notifiers and Mixin bot already call `avatar_url` expecting a fetchable URL. A single breaking nil return would break notification cards. External callers keep working; web views migrate to the partial and ignore the icon fallback.

**Alternative considered:** Return nil everywhere and update all notifiers — more breaking, no user-visible benefit.

### 3. Initials in ERB, color in Stimulus

**Choice:** Render initials text server-side from `user.name` in the partial; Stimulus controller sets background color from `mixin_uuid` seed on connect.

**Rationale:** Avoids flash of unstyled gray circle on slow JS load. Initials are display of stored name data, not generated imagery. Color is the distinctive generated element and lives in JS.

**Alternative considered:** Both in JS — purer "frontend only" but worse perceived performance.

### 4. Initials algorithm

**Choice:**

- Split name on whitespace
- Take first grapheme of first token; if multiple tokens, also take first grapheme of second token
- Uppercase Latin characters; leave CJK unchanged
- Max 2 characters
- Use `Intl.Segmenter` when available; fall back to first code point

**Rationale:** Mixin user base includes CJK names. Single-character CJK initials are standard.

### 5. Color algorithm

**Choice:** FNV-1a or djb2 hash of `mixin_uuid` string → hue 0–359; saturation 65%; lightness 45%. White text (`text-white`).

**Rationale:** Deterministic, stable per user, sufficient visual variety, readable contrast.

### 6. Shared partial API

**Choice:** `render "shared/avatar", user:, class: "size-10"` — partial accepts optional `class` for sizing, optional `thumb: true` to prefer thumb variant when real image exists.

**Rationale:** Matches existing inconsistent size classes at call sites without forcing a size enum.

### 7. JS utility module

**Choice:** `app/javascript/utils/avatar.js` exports `initials(name)`, `colorFromSeed(seed)`, `renderAvatarHtml({ seed, name, className })` for Tom Select and other non-Stimulus consumers.

**Rationale:** Avoid duplicating hash/initials logic in `references_select_controller.js`.

### 8. API contract

**Choice:** When no real avatar, JSON returns `"avatar": null` plus `"avatar_seed": "<mixin_uuid>"` and `"avatar_initials": "TA"`.

**Rationale:** Mobile/API clients can render the same placeholder without reimplementing initials logic if they choose; initials precomputed for convenience.

### 9. Scope includes sibling models

**Choice:** Remove Multiavatar from `User`, `MixinNetworkUser`, and `NftCollection` in the same change. `MixinNetworkUser` already has `DEFAULT_AVATAR_FILE` / platform icon pattern for uploads — reuse for its external fallback.

## Risks / Trade-offs

- **[Risk] Visual regression vs Multiavatar** → Initials are simpler but functional; users with OAuth avatars unaffected
- **[Risk] Grover poster shows platform icon instead of initials** → Acceptable; poster is share collateral, icon is acceptable fallback. Could revisit with headless JS rendering later
- **[Risk] ~35 view replacements is mechanical but wide** → Mitigate with shared partial; grep-driven migration
- **[Risk] API clients break on null avatar** → Document new fields; only affects users without real avatars (currently broken anyway)
- **[Risk] Notifier tests assert exact avatar_url** → Update tests to expect icon fallback when fixture users lack OAuth avatar

## Migration Plan

1. Add partial, Stimulus controller, and JS utils (no behavior change yet)
2. Update model methods to remove Multiavatar; add external fallback
3. Replace view call sites with partial (can be done incrementally but ship together)
4. Update API jbuilders and JS consumers
5. Update tests
6. No database migration required; no feature flag needed

**Rollback:** Revert commit; no data changes to undo.

## Open Questions

- None blocking implementation. Grover initials rendering deferred to a follow-up if posters need branded placeholders instead of platform icon.
