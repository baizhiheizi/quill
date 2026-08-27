# Quill — Value Net · Web Design System Bound

> Summary: An editorial-first, Web3-contextual publishing UI — near-grayscale
> monochrome with a single cobalt accent reserved for actions/links/focus, and
> one muted-amber tint reserved for reward/early-reader figures (text only).

## Brand

- **Name:** Quill
- **Mark:** circular cobalt (`#5C6BEF`) badge with a white quill/pen-nib. Wordmark "Quill." rendered in the display serif.
- **Kept as-is** (per brief): the logo mark and its idea. Everything else redesigned.

## Six tokens (OKLch)

Bound from `app/assets/stylesheets/application.tailwind.css` (FlyonUI `quill` / `quill-dark` themes) and `docs/superpowers/specs/2026-07-03-ui-redesign-design.md`.

| Role   | Light                              | Dark                               | Usage |
|--------|-------------------------------------|-------------------------------------|-------|
| `--bg`      | `oklch(1 0 0)`        | `oklch(0.178 0 0)`      | page background |
| `--surface` | `oklch(0.985 0 0)`    | `oklch(0.205 0 0)`      | cards, raised surfaces |
| `--fg`      | `oklch(0.178 0 0)`    | `oklch(0.945 0 0)`      | headlines, body |
| `--muted`   | `oklch(0.556 0 0)`    | `oklch(0.71 0 0)`       | meta, captions, secondary |
| `--border`  | `oklch(0.94 0 0)`     | `oklch(0.29 0 0)`       | hairlines, dividers |
| `--accent`  | `oklch(0.543 0.252 267.5)` | `oklch(0.655 0.183 271.8)` | links, primary buttons, focus, active nav |
| `--reward`  | `oklch(0.543 0.103 75.5)` | `oklch(0.756 0.117 77.6)` | early-reader % / earnings — **text only, never a filled badge** |

## Type

| Role | Latin | CJK (fallback) | Weight | Used for |
|---|---|---|---|---|
| Display | Newsreader | Noto Serif SC | 500–600 | titles, headings, masthead wordmark |
| Body + UI | Inter | Noto Sans SC | 400–600 | nav, buttons, meta, article body |
| Mono | Roboto Mono | JetBrains Mono | 400–500 | numerics, code, captions, eyebrows |

```css
--font-display: 'Newsreader','Noto Serif SC',ui-serif,Georgia,serif;
--font-body:    'Inter','Noto Sans SC',ui-sans-serif,system-ui,sans-serif;
--font-mono:    'Roboto Mono','JetBrains Mono',ui-monospace,monospace;
```

## Rules of the language

1. **Near-grayscale + one accent.** Backgrounds, dividers, and most UI are neutral. The cobalt accent appears at most twice per screen (eyebrow + primary CTA is the default budget).
2. **Editorial-first, Web3-contextual.** Reading/writing surfaces look like a quiet premium publisher; wallet, payment, and reward UI appears only in context, never as permanent chrome.
3. **Reward is text, never a badge.** Early-reader figures use muted amber text in the meta line. Topic tags are one neutral gray chip; price/free are solid pills.
4. **Dense, scannable lists.** Feed rows are divided by thin horizontal rules, not card borders; serif title ≈17px, one-line muted excerpt, right-rounded thumbnail.
5. **First-class dark mode.** Both themes are designed and reviewed equally; a global toggle is available.
6. **Reading measure.** Article body is capped at a comfortable ~68ch; chrome stays slim.

## Source of truth

Quill repo design tokens + UI-redesign spec. Reused (not recreated): logo, color values, font stacks, radius (`--radius-box: 0.75rem`, `--radius-field: 0.5rem`).
