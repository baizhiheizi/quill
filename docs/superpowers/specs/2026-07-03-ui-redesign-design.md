# Quill UI Redesign — Design Spec

Status: Approved (design phase) · Date: 2026-07-03

## 1. Problem & Goal

Quill's current UI (Tailwind v4 + FlyonUI, indigo brand, left-sidebar app shell) reads as a generic dashboard/dapp rather than a publishing product. The goal is to redesign the visual language and page layouts to feel like an editorial, Web3-native publishing platform in the spirit of [Paragraph](https://paragraph.com/) and [Substack](https://substack.com/) — content-first, minimal chrome, Web3 elements present only where contextually relevant (paywall, rewards, wallet).

This spec defines a **general design system** (colors, typography, layout shell, component patterns) and applies it to the highest-traffic public pages. It intentionally does **not** cover the author dashboard/studio, article editor, admin panel, or the wallet-connect modal internals — see [§8 Out of Scope](#8-out-of-scope-follow-up-phases).

## 2. Design Principles

1. **Editorial-first, Web3-contextual.** Reading/writing surfaces feel like a quiet, premium publishing product, not a dapp. Wallet/payment/reward UI shows up precisely where relevant (byline, paywall, reward badge) — never as constant chrome.
2. **Monochrome + one accent.** Near-grayscale UI (white/black/gray) with a single accent color reserved for primary actions, links, and focus states. Color carries meaning, not decoration.
3. **Density over decorative whitespace.** The feed is a scannable list optimized for fast reading, not a magazine grid.
4. **Chinese-first typography.** Most content on the platform is Chinese. Every typographic decision optimizes for CJK legibility first, Latin second.
5. **Dark mode is first-class**, not an afterthought — designed and reviewed with equal care to light mode.

## 3. Scope

**In scope (this spec):**
- Home / article feed (`home#index`, logged-in and logged-out states)
- Article reader (`articles#show`)
- Author public profile (`users#show`)
- Search results
- Collection page

**Explicitly out of scope** (existing styling untouched for now — see §8): author dashboard/studio, article editor, admin panel, wallet-connect/login modal internals, notifications page.

## 4. Visual System

### 4.1 Color

Both themes are first-class deliverables, not one primary + one fallback.

| Token | Light | Dark | Usage |
|---|---|---|---|
| `base-100` (background) | `#FFFFFF` | `#111111` | Page background |
| `base-200` (surface) | `#FAFAFA` | `#181818` | Cards, raised surfaces |
| `base-300` (border/divider) | `rgba(0,0,0,.08)` | `rgba(255,255,255,.10)` | Dividers, card borders |
| `base-content` (text primary) | `#111111` | `#F2F2F2` | Headlines, body |
| `base-content/60` (text muted) | `rgba(0,0,0,.55–.6)` | `rgba(255,255,255,.55–.6)` | Meta, timestamps, secondary text |
| `primary` (accent) | `#3355FF` | `#6B84FF` | Links, primary buttons, focus rings, active nav state |
| Reward/bonus tint | `#92661C` (muted amber), text only | `#D9A653` | Early-reader bonus %, earnings figures — text color only, never a filled badge |

Removed: the current 6-color pastel `tag-style-0..5` utility system. Replaced by a single neutral gray chip style for topic tags (see §5.3). Price/free badges use black (paid) / light-gray (free) solid pills, not brand color, to keep the accent reserved for actions.

### 4.2 Typography

| Role | Latin | CJK | Weight | Used for |
|---|---|---|---|---|
| Headline/display | Newsreader | Noto Serif SC | 500–600 | Article titles, feed card titles, page headers, masthead wordmark treatment |
| UI + body | Inter | Noto Sans SC | 400–600 | Navigation, buttons, meta text, form fields, **and article body copy** |
| Mono | Roboto Mono / JetBrains Mono (unchanged) | — | 400–500 | Code blocks |

Rationale: headline serif carries the "editorial" signal; body stays sans for long-form legibility, matching Chinese-reader norms (知乎/微信-style) and validated directly against real paragraph-length Chinese sample text.

Font stack example (Tailwind `@theme`):
```css
--font-display: 'Newsreader', 'Noto Serif SC', ui-serif, serif;
--font-sans: 'Inter', 'Noto Sans SC', ui-sans-serif, system-ui, sans-serif;
--font-mono: 'Roboto Mono', 'JetBrains Mono', ui-monospace, monospace;
```
Google Fonts serves CJK families pre-split by unicode-range, so no manual subsetting is required to keep payload reasonable.

### 4.3 Icons

Migrate from hand-rolled inline SVGs (`icons/*.svg`, referenced via `inline_svg_tag`) to **Tabler icons via `@iconify/tailwind4`** utility classes (`i-tabler-*`). Both dependencies are already installed but unused. This gives one consistent stroke width/style and removes the need to hand-maintain SVG files per icon. Migrate incrementally, file by file, as pages are touched — no need for a single big-bang icon swap.

### 4.4 Radius & Elevation

Keep the existing FlyonUI radius tokens (`--radius-selector: 1rem`, `--radius-field: 0.5rem`, `--radius-box: 0.75rem`) — they already suit the softer pill/rounded-card aesthetic. Avoid box-shadows for elevation; use `border` + subtle background differences (`base-100` vs `base-200`) instead, consistent with the monochrome-editorial direction.

## 5. Layout Shell (in-scope pages)

Top-nav, single centered content column — **no persistent left sidebar and no persistent right widget rail** on public pages (this replaces the current fixed left-sidebar app shell for these pages only).

### 5.1 Top bar
- Sticky, thin bottom border (no shadow), background = `base-100`.
- Left: logo/wordmark. Center or left-adjacent: primary nav (Home, Search). Right: Write CTA (pill button), wallet/profile control, dark-mode toggle, locale switcher.
- Logged-out state: Write CTA becomes "Connect Wallet" (opens existing login modal — unchanged).

### 5.2 Content column
- Feed/list pages: comfortable row width, full column used for scannability.
- Article reader: content column capped at a comfortable reading measure (~`65ch`/680px equivalent), independent of the outer page width.
- Contextual widgets that previously lived in the right rail (active authors, hot tags, footer links) move into a compact horizontal strip below the masthead on the home page, or into the page footer — not a sticky sidebar card.

### 5.3 Responsive behavior
- Mobile: top bar collapses to logo + essential actions (existing bottom tabbar can remain for logged-in primary navigation — restyle only, not restructure, since it's out of scope for structural change).

## 6. Core Components

### 6.1 Feed/article row ("Minimal List")
Thin horizontal divider between rows (no card borders on the list itself). Per row, left-to-right:
- Text block (flex: 1): tag chip + price/free badge (small, above title) → serif title (headline font, ~17px) → one-line sans excerpt (muted) → meta row (avatar 20px, author name, relative date, reward indicator e.g. "早期读者 +18%" in amber text when applicable).
- Thumbnail: small square (~88px), rounded corners, right-aligned, flex-shrink-0.

This single component is reused for: home feed, search results, author profile article list, collection article list.

### 6.2 Tag & status chips
- Topic tag: neutral gray pill (`base-200` background, `base-content/70` text) — replaces the 6-color category system.
- Price badge (paid article): solid black (light) / white (dark) pill, e.g. `¥128`.
- Free badge: light-gray pill, e.g. `免费`.
- Reward/bonus indicator: plain text in the muted-amber tint, not a filled pill — appears inline in the meta row only when relevant.

### 6.3 Paywall
Fade-to-blur treatment: the last visible paragraph of a locked article fades under a vertical gradient (`base-100` at full opacity increasing toward the bottom), with an inline unlock card ("解锁全文 · ¥128") overlapping the fade area. Replaces any hard-break paywall banner. The buy/support action becomes a slim sticky bar (top or bottom of viewport) rather than a right-sidebar card, consistent with the single-column article layout.

### 6.4 Author profile header
Avatar, name, bio, and **modest public stats only**: article count, total reader count, join date. No earnings, revenue, or on-chain financial data is shown on the public profile — that remains dashboard-only (out of scope here). Below the header: the author's articles rendered via the same Minimal List row component (§6.1).

### 6.5 Buttons
- Primary actions (Write, Connect Wallet, Unlock article): pill / `rounded-full`, accent-filled.
- Secondary/inline actions: `rounded-md`, outline or ghost style.

## 7. Page-by-Page Application

- **Home / feed** (`home#index`): slim masthead — no full-height hero banner. Logged-out visitors see a single-line value proposition next to/below the masthead; logged-in users see none. The article feed (Minimal List rows) begins immediately below, infinite-scroll unchanged.
- **Article reader** (`articles#show`): single column, serif headline + sans body copy throughout, fade-blur paywall (§6.3), sticky slim support/buy bar, comments and votes below the fold, author byline card at the end of the article rather than a sidebar.
- **Author profile** (`users#show`): header per §6.4, followed by their articles as Minimal List rows.
- **Search**: search input integrated into the masthead area; results rendered as Minimal List rows (reuses §6.1 directly, no bespoke result component).
- **Collection page**: collection header (title, description, curator byline) followed by its articles as Minimal List rows.

## 8. Out of Scope (Follow-up Phases)

Documented here so the direction is consistent when these are tackled later, but not designed in detail in this pass:

- **Author dashboard/studio** (drafts, stats, earnings, payments, settings): keep a **restyled left-sidebar** shell here (denser navigation genuinely earns its keep in a studio context), rather than top-nav. Should inherit the same color/type tokens from this spec.
- **Article editor**: not addressed; likely inherits typography tokens but needs its own pass given its distinct toolbar/writing-surface needs.
- **Admin panel**: internal tool, not addressed.
- **Wallet-connect/login modal internals**: not addressed; only the trigger buttons (Write/Connect Wallet CTA) are covered by this spec.

## 9. Implementation Notes (non-binding, for the follow-up plan)

- Tailwind theme (`app/assets/stylesheets/application.tailwind.css`): update `--color-primary` and related FlyonUI theme blocks for both `quill` and `quill-dark` themes per §4.1; add `--font-display` token; swap Google Fonts `<link>` tags in layouts for the new families + CJK counterparts.
- Remove `tag-style-0..5` utilities; add a single neutral tag-chip utility.
- New/updated partials likely needed: masthead/top-nav (replacing `shared/_left_bar` + `shared/_navbar` for in-scope pages), a shared "minimal list row" partial (replacing/superseding `articles/_preview`), paywall fade component, author profile header partial.
- Icon migration: introduce `i-tabler-*` classes incrementally; leave `inline_svg_tag` usages alone until each view is touched.
- No structural change needed for mobile bottom tabbar in this pass (restyle only).

## 10. Open Questions for Implementation Planning

- Exact breakpoint behavior for the masthead nav on tablet widths.
- Whether the "active authors" / "hot tags" widgets get a new compact presentation or are deprioritized/removed from public pages entirely.
- Migration order across the 5 in-scope pages (recommend: shared components + home feed first, since Minimal List is reused everywhere else).
