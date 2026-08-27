# Tokens Contract

> The single source-of-truth for design tokens. Every view, partial, Stimulus controller, and stylesheet rule MUST consume these via Tailwind utilities or CSS custom properties. New tokens MUST be added here before use.

## Color tokens

The base palette is bound to the existing FlyonUI `quill` / `quill-dark` themes in `app/assets/stylesheets/application.tailwind.css`. The brand-spec layer adds OKLCh raw values as `:root` CSS custom properties for components that need them outside Tailwind utilities.

| Token | Light | Dark | Tailwind class | CSS var | Usage |
|---|---|---|---|---|---|
| `bg` | `oklch(1 0 0)` | `oklch(0.178 0 0)` | `bg-base-100` | `--bg` | page background |
| `surface` | `oklch(0.985 0 0)` | `oklch(0.205 0 0)` | `bg-base-200` | `--surface` | cards, raised surfaces |
| `fg` | `oklch(0.178 0 0)` | `oklch(0.945 0 0)` | `text-base-content` | `--fg` | headlines, body |
| `muted` | `oklch(0.556 0 0)` | `oklch(0.71 0 0)` | `text-base-content/60` | `--muted` | meta, captions |
| `border` | `oklch(0.94 0 0)` | `oklch(0.29 0 0)` | `border-base-300` | `--border` | hairlines, dividers |
| `accent` | `oklch(0.543 0.252 267.5)` | `oklch(0.655 0.183 271.8)` | `text-primary`, `bg-primary`, `text-accent`, `bg-accent` | `--accent` | links, primary buttons, focus, active nav (≤ 2 per screen) |
| `reward` | `oklch(0.543 0.103 75.5)` | `oklch(0.756 0.117 77.6)` | `text-reward` (already declared; **no `bg-reward`, `border-reward` utility is provided**) | `--reward` | early-reader % / earnings — **text only, never a filled badge** |
| `success` | `oklch(0.723 0.192 149.6)` | `oklch(0.772 0.17 149.6)` | `bg-success` | `--success` | success toasts / pills |
| `warn` | `oklch(0.747 0.110 58.2)` | `oklch(0.802 0.115 74.0)` | `bg-warning` | `--warn` | warning toasts / pills |
| `danger` | `oklch(0.645 0.211 27.2)` | `oklch(0.706 0.20 25.0)` | `bg-error` | `--danger` | destructive confirmations |
| `ring` | `color-mix(in oklch, var(--accent) 50%, transparent)` | `color-mix(in oklch, var(--accent) 60%, transparent)` | `focus-visible:ring-2 focus-visible:ring-ring` | `--ring` | keyboard focus rings |

### Coin brand marks (kept as-is, like the Quill logo)

| Token | Value | Usage |
|---|---|---|
| `--coin-btc` | `#f7931a` | Bitcoin payment asset mark |
| `--coin-eth` | `#627eea` | Ethereum payment asset mark |
| `--coin-xin` | `#5c6bef` | Mixin (XIN) payment asset mark |
| `--coin-pusd` | `#0b3d91` | pUSD payment asset mark |

These four are the only raw hex literals allowed outside the `:root` token block.

## Typography tokens

| Role | Latin | CJK fallback | Tailwind class | CSS var |
|---|---|---|---|---|
| Display | Newsreader | Noto Serif SC | `font-display` | `--font-display` |
| Body + UI | Inter | Noto Sans SC | `font-sans` (default) | `--font-body` |
| Mono | Roboto Mono | JetBrains Mono | `font-mono` | `--font-mono` |

### Scale

| Role | Size | Tailwind class |
|---|---|---|
| H1 | `clamp(30px, 4vw, 44px)` | `text-3xl sm:text-4xl font-display` |
| H2 | `clamp(24px, 3vw, 32px)` | `text-2xl sm:text-3xl font-display` |
| H3 | `19px` | `text-[19px] font-display` |
| Lead | `17px` | `text-[17px]` |
| Body | `16px` | `text-base` |
| Meta | `13px` | `text-[13px]` |

## Radius tokens

| Token | Value | Tailwind class | Used by |
|---|---|---|---|
| `radius-selector` | `1rem` | (FlyonUI internal) | FlyonUI components |
| `radius-field` | `0.5rem` | (FlyonUI internal) | FlyonUI inputs |
| `radius-box` | `0.75rem` | (FlyonUI internal) | FlyonUI boxes |
| `radius` | `10px` | `rounded-[10px]` | brand-spec primitive (default) |
| `radius-lg` | `14px` | `rounded-[14px]` | brand-spec primitive (large) |
| `radius-full` | `999px` | `rounded-full` | pills, avatars |

## Spacing scale (8pt grid)

| Token | Value | Tailwind class |
|---|---|---|
| `gap-xs` | `8px` | `gap-2` |
| `gap-sm` | `12px` | `gap-3` |
| `gap-md` | `20px` | `gap-5` |
| `gap-lg` | `32px` | `gap-8` |
| `gap-xl` | `56px` | `gap-14` |
| `gap-2xl` | `96px` | `gap-24` |
| `container` | `1120px` | `max-w-[1120px]` |
| `measure` | `68ch` | `max-w-[68ch]` |
| `gutter` | `clamp(20px, 4vw, 48px)` | `px-5 sm:px-12` |

## Motion tokens

| Token | Value | Usage |
|---|---|---|
| `ease-default` | `cubic-bezier(0.2, 0.8, 0.2, 1)` | default transitions |
| `duration-fast` | `120ms` | hover state changes |
| `duration-default` | `200ms` | modal / dropdown open |
| `duration-slow` | `320ms` | page transition (none today; reserved) |

## Enforcement

`bin/lint-design-system` enforces:

1. No raw hex outside `:root` and the four `--coin-*` vars.
2. No new `--color-*` declared outside `@plugin 'flyonui/theme'` or `@theme` blocks.
3. Every `font-*` Tailwind class maps to one of `font-display`, `font-sans`, `font-mono` (the default `font-sans` is implicit; explicit `font-sans` is allowed but not required).
4. No `bg-reward` or `border-reward` Tailwind class. (`text-reward` is allowed.)
5. No literal `border-radius:` value in component CSS outside the `:root` radius block.

Violations fail CI; the script emits one violation per line as `file:line: rule: message`.