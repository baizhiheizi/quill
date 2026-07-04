# Quickstart: Validating Editorial UI Polish Pass

Manual + automated validation for `specs/006-editorial-ui-polish/`. Run after implementation or incrementally per user story (P1–P6).

## Prerequisites

```bash
bundle install
bun install
bin/rails db:prepare
bin/dev   # Rails + CSS/JS watchers
```

Visit `http://localhost:3000`.

## Automated checks

```bash
bin/rubocop
bun run lint-check
bin/rails test
```

### Grep audit (SC-002–SC-005)

```bash
# Zero ghost buttons in in-scope views (admin excluded)
grep -rn "btn-ghost\|badge-ghost" app/views --include="*.erb" | grep -v admin || echo "PASS: no ghost classes"

# Zero inline_svg in in-scope directories
grep -rl "inline_svg_tag" app/views/articles app/views/comments app/views/shared app/views/subscribe_users app/views/subscribe_tags app/views/subscribe_articles app/views/pre_orders app/views/sessions app/views/locales app/views/block_users app/views/pages app/views/dashboard 2>/dev/null || echo "PASS: no inline_svg in scope"

# Zero wrong icon prefix
grep -rn "icon-\[tabler" app/views --include="*.erb" | grep -v admin || echo "PASS: no icon-[tabler prefix"

# Zero hardcoded #B1B6C6 in interaction components
grep -rn "#B1B6C6" app/views --include="*.erb" || echo "PASS: no legacy gray hex"
```

## Manual validation per user story

Check **light and dark mode** and **desktop + mobile** unless noted.

### Story 1 — Shared dialogs

1. Open connect-wallet modal (logged out → masthead CTA). Confirm rounded border, display-font title, soft close button, editorial spacing.
2. Open locale picker (masthead globe). Confirm same shell treatment.
3. Open profile dropdown (logged in). Confirm rounded panel, border, hover states.
4. Tab to close button and primary action — confirm visible focus ring.

### Story 2 — Icon system

1. Open any article with comments. Inspect vote, share, comment action icons — all Tabler stroke icons, no mixed SVG files.
2. Toggle dark mode — inactive icons use muted token color, not fixed light-gray hex.

### Story 3 — Article interactions

1. Vote on an article (up/down). Confirm circular buttons, ratio bar, hover states match editorial density.
2. Open share modal — uniform icon sizes for Twitter, Telegram, copy URL.
3. Subscribe to an author from their profile — consistent pill button with plus icon.

### Story 4 — Secondary modals

1. Locale picker — pill buttons with clear selected state.
2. Pre-order modal (paid article reward) — editorial form styling, token borders on amount options.
3. Comment reply modal — primary submit button, readable form.
4. Block-user confirmation — full-width error/danger button, not raw red block.

### Story 5 — Styling debt

1. Article editor toolbar — all low-emphasis buttons show soft background (no unstyled ghost).
2. Flash notification — appears with Tabler icon, dismissible, readable in both themes.

### Story 6 — Accessibility

1. Keyboard-only: open modal → Tab through controls → Escape/close works.
2. Dark mode: all polished surfaces meet readable contrast (no washed-out inactive icons).

## Regression smoke

- Wallet connect flow completes.
- Vote/comment/share/subscribe actions behave as before.
- Locale switch applies.
- Block user action succeeds.
- Pre-order form submits.
