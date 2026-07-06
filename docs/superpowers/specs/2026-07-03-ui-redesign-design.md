# Quill UI Redesign — Design Spec

Status: Approved (design phase) · Date: 2026-07-03

## 1. Goal and scope

Quill's current UI (Tailwind v4 + FlyonUI, indigo brand, left-sidebar app shell) reads as a generic dashboard/dapp rather than an editorial publishing product. This redesign moves the public experience toward a content-first, Web3-native feel in the spirit of [Paragraph](https://paragraph.com/) and [Substack](https://substack.com/): minimal chrome, strong reading surfaces, and wallet/payment/reward UI only where context requires it.

This spec defines the shared visual system and applies it to the highest-traffic public pages. Dashboard/studio, editor, admin, and wallet-modal internals are follow-up phases.

| In scope | Out of scope for this pass |
|---|---|
| Home/article feed (`home#index`, logged-in and logged-out), article reader (`articles#show`), author profile (`users#show`), search results, collection page | Author dashboard/studio, article editor, admin panel, wallet-connect/login modal internals, notifications page |

Follow-up direction: the author dashboard/studio should keep a restyled left-sidebar shell because dense navigation fits that context. The editor may inherit the same typography tokens but needs its own writing-surface pass; admin remains an internal tool; only wallet/login trigger buttons are covered here.

## 2. Design direction

1. **Editorial-first, Web3-contextual.** Reading and writing surfaces feel like a quiet premium publishing product; wallet, payment, and reward UI appears only in context.
2. **Monochrome + one accent.** Near-grayscale UI with one accent for primary actions, links, focus states, and active navigation.
3. **Dense, scannable feeds.** Prefer list density over decorative whitespace; the feed optimizes for fast reading, not magazine layout.
4. **Chinese-first typography.** Most content is Chinese, so CJK legibility leads every type choice.
5. **First-class dark mode.** Light and dark themes are designed and reviewed equally.

## 3. Visual system

### 3.1 Color

Both themes are first-class deliverables.

| Token | Light | Dark | Usage |
|---|---|---|---|
| `base-100` | `#FFFFFF` | `#111111` | Page background |
| `base-200` | `#FAFAFA` | `#181818` | Cards, raised surfaces |
| `base-300` | `rgba(0,0,0,.08)` | `rgba(255,255,255,.10)` | Dividers, card borders |
| `base-content` | `#111111` | `#F2F2F2` | Headlines, body |
| `base-content/60` | `rgba(0,0,0,.55–.6)` | `rgba(255,255,255,.55–.6)` | Meta, timestamps, secondary text |
| `primary` | `#3355FF` | `#6B84FF` | Links, primary buttons, focus rings, active nav state |
| Reward/bonus tint | `#92661C` | `#D9A653` | Early-reader bonus %, earnings figures; text only, never a filled badge |

Remove the current 6-color pastel `tag-style-0..5` utilities. Topic tags become a single neutral gray chip; price/free badges use black or light-gray solid pills so the accent stays reserved for actions.

### 3.2 Typography

| Role | Latin | CJK | Weight | Used for |
|---|---|---|---|---|
| Headline/display | Newsreader | Noto Serif SC | 500–600 | Article titles, feed titles, page headers, masthead wordmark |
| UI + body | Inter | Noto Sans SC | 400–600 | Navigation, buttons, meta text, form fields, and article body copy |
| Mono | Roboto Mono / JetBrains Mono (unchanged) | — | 400–500 | Code blocks |

Headline serif adds the editorial signal; sans body text matches Chinese long-form norms and stays legible in paragraph-length samples.

```css
--font-display: 'Newsreader', 'Noto Serif SC', ui-serif, serif;
--font-sans: 'Inter', 'Noto Sans SC', ui-sans-serif, system-ui, sans-serif;
--font-mono: 'Roboto Mono', 'JetBrains Mono', ui-monospace, monospace;
```

Google Fonts serves CJK families with unicode-range splitting, so no manual subsetting is needed.

### 3.3 Icons, radius, elevation

Migrate from hand-rolled inline SVGs (`icons/*.svg` via `inline_svg_tag`) to Tabler icons through `@iconify/tailwind4` (`i-tabler-*`). Both dependencies are already installed; migrate incrementally as pages are touched.

Keep the existing FlyonUI radius tokens (`--radius-selector: 1rem`, `--radius-field: 0.5rem`, `--radius-box: 0.75rem`). Avoid box shadows; use borders and subtle `base-100`/`base-200` background contrast for elevation.

## 4. Public layout shell

Public pages use a top-nav and one centered content column — no persistent left sidebar or sticky right widget rail.

| Area | Direction |
|---|---|
| Top bar | Sticky with a thin bottom border, `base-100` background, no shadow. Left logo/wordmark; center or left-adjacent Home/Search; right Write CTA, wallet/profile control, dark-mode toggle, locale switcher. Logged-out Write becomes Connect Wallet and opens the existing login modal. |
| Feed/list column | Comfortable row width using the full column for scannability. |
| Article reader | Capped at a comfortable reading measure (`~65ch` / `680px`) independent of outer page width. |
| Former right-rail widgets | Active authors, hot tags, and footer links move into a compact strip below the home masthead or into the footer. |
| Mobile | Top bar collapses to logo plus essential actions. The existing logged-in bottom tabbar may remain structurally unchanged; restyle only. |

## 5. Core components

| Component | Direction |
|---|---|
| Minimal List row | Reused by home feed, search, author profile, and collection lists. Rows are divided by thin horizontal rules, not card borders. Left text block: neutral tag chip + price/free badge, serif title around 17px, one-line muted excerpt, meta row with 20px avatar, author, relative date, and optional amber reward text such as `早期读者 +18%`. Right thumbnail: square `~88px`, rounded, right-aligned, `flex-shrink-0`. |
| Tag and status chips | Topic tag: neutral gray pill (`base-200`, `base-content/70`). Paid badge: solid black in light mode / white in dark mode, e.g. `¥128`. Free badge: light-gray pill, e.g. `免费`. Reward/bonus remains plain muted-amber text in the meta row only. |
| Paywall | Locked articles fade the last visible paragraph under a vertical `base-100` gradient, with an inline unlock card (`解锁全文 · ¥128`) overlapping the fade. Buy/support actions move to a slim sticky bar instead of a right-sidebar card. |
| Author profile header | Avatar, name, bio, and public stats only: article count, total reader count, join date. Earnings, revenue, and on-chain financial data remain dashboard-only. |
| Buttons | Primary actions (Write, Connect Wallet, Unlock article) are accent-filled pills. Secondary/inline actions use `rounded-md` outline or ghost styles. |

## 6. Page application

| Page | Application |
|---|---|
| Home/feed (`home#index`) | Slim masthead, no full-height hero. Logged-out visitors see a one-line value proposition; logged-in users do not. Feed starts immediately below and keeps existing infinite scroll. |
| Article reader (`articles#show`) | Single column, serif headline, sans body copy, fade-blur paywall, sticky slim support/buy bar, comments and votes below the fold, author byline card at article end. |
| Author profile (`users#show`) | Header from §5, followed by Minimal List rows. |
| Search | Search input integrated into the masthead; results use Minimal List rows with no bespoke result component. |
| Collection page | Collection header with title, description, and curator byline, followed by Minimal List rows. |

## 7. Implementation notes and open questions

Implementation notes:

- Update `app/assets/stylesheets/application.tailwind.css`: `--color-primary`, related FlyonUI theme blocks for `quill` / `quill-dark`, and `--font-display`.
- Swap Google Fonts links in layouts for the new Latin + CJK families.
- Replace `tag-style-0..5` with one neutral tag-chip utility.
- Add/update partials for masthead/top-nav, Minimal List row, paywall fade, and author profile header; the masthead supersedes `shared/_left_bar` + `shared/_navbar` on in-scope pages only.
- Introduce `i-tabler-*` classes as each view is touched; leave existing `inline_svg_tag` usages until then.
- Restyle the mobile bottom tabbar only; no structural change in this pass.

Open questions for planning:

- Exact masthead breakpoint behavior on tablet widths.
- Whether active-authors / hot-tags widgets get compact presentation or are removed from public pages.
- Migration order across the five in-scope pages; recommended order is shared components + home feed first because Minimal List is reused everywhere.
