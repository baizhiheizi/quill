# Phase 0 Research: Editorial UI Polish Pass

All technical unknowns resolved before Phase 1 design. No `NEEDS CLARIFICATION` markers remain.

## 1. Which Tabler icon utility prefix is canonical?

**Decision**: Standardize on `i-[tabler--*]` everywhere — the prefix configured in `application.tailwind.css` (`@plugin '@iconify/tailwind4' { prefix: 'i'; }`).

**Rationale**: The masthead and most of the prior redesign already use `i-[tabler--edit]`, `i-[tabler--bell]`, etc. A handful of files (`shared/_modal.html.erb`, `flashes/_alert_content.html.erb`, `shared/_share_options.html.erb`) incorrectly use `icon-[tabler--*]`, which bypasses the configured prefix and may not be content-scanned consistently. One convention eliminates SC-005 failures.

**Alternatives considered**: Switch everything to `icon-[tabler--*]` — rejected; fights the explicit `prefix: 'i'` config and the majority of existing call sites.

## 2. Tabler equivalents for remaining hand-rolled SVGs

**Decision**: Map each `inline_svg_tag 'icons/*.svg'` to the closest Tabler icon at equivalent visual weight:

| Legacy SVG | Tabler class | Notes |
|---|---|---|
| `like-solid.svg` | `i-[tabler--thumb-up-filled]` | Filled variant for active vote states |
| `dislike-solid.svg` | `i-[tabler--thumb-down-filled]` | Filled variant for active downvote |
| `reply-solid.svg` | `i-[tabler--arrow-back-up]` | Reply/quote action |
| `share-solid.svg` | `i-[tabler--share-3]` | Share action |
| `add.svg` | `i-[tabler--plus]` | Subscribe CTA |
| `copy.svg` | `i-[tabler--copy]` | Copy URL in share sheet |
| `check-circle-solid.svg` | `i-[tabler--circle-check-filled]` | Saved/checkmark indicator |
| `chevron-left.svg` | `i-[tabler--chevron-left]` | Back navigation on static pages |

**Rationale**: Tabler ships filled variants for thumb icons matching the prior solid SVG intent. No custom SVG files needed (FR-004, spec assumption).

**Alternatives considered**: Keep solid SVGs for vote buttons only — rejected; violates the approved design direction (§4.3) and leaves two icon systems on the same article page.

## 3. How should the shared modal be polished without breaking FlyonUI behavior?

**Decision**: Add editorial Tailwind utility classes to `_modal.html.erb` only — `rounded-2xl`, `border border-base-300`, `shadow-none`, `font-display` on title, increased padding, `btn-soft` on close — without changing `data-controller`, `role`, Turbo Frame wiring, or FlyonUI `overlay`/`modal-*` class hooks.

**Rationale**: FlyonUI's overlay controller (`flyonui_modal_controller.js` / `HSOverlay`) depends on the existing class structure. Visual polish is achieved via additive utilities on `modal-content`, `modal-header`, `modal-body`, matching the monochrome border-elevation pattern from the design doc §4.4.

**Alternatives considered**: Replace FlyonUI modal with a custom Stimulus dialog — rejected; wide blast radius, no functional benefit, violates constitution III (reuse existing patterns).

## 4. Hardcoded hex colors to replace

**Decision**: Replace interaction-component hex values with design tokens:

| Legacy | Token |
|---|---|
| `#B1B6C6` (inactive icon gray) | `text-base-content/60` |
| `text-red-500` (active downvote) | `text-error` |
| `text-green-500` (saved checkmark) | `text-success` |
| `border-zinc-200 dark:border-zinc-600` (pre-order options) | `border-base-300` |
| `bg-red-500 text-white` (block user) | `btn btn-error btn-lg w-full rounded-full` |

**Rationale**: Tokens adapt to both `quill` and `quill-dark` themes automatically (FR-005, SC-004).

## 5. Is `shared/_nav_icon_link.html.erb` still used?

**Decision**: The partial has zero render call sites in the repo (grep confirmed). Still migrate its `inline_svg_tag` to Tabler (`i-[tabler--#{icon}]` with `icon` local changed from file path to Tabler slug) so SC-002 passes if the partial is ever reintroduced; no caller updates needed.

**Alternatives considered**: Delete the dead partial — rejected for this feature; out of scope deletion risk without user request.

## 6. Testing scope for presentation-only changes

**Decision**: No new automated tests; verify with `bin/rubocop`, `bun run lint-check`, `bin/rails test`, and the manual quickstart checklist. Existing system tests that render modals/partials continue to pass unchanged.

**Rationale**: Spec assumption and constitution II — purely presentational tweaks with no behavioral impact.

## 7. Admin panel boundary

**Decision**: `app/views/admin/_aside.html.erb` inline SVGs remain untouched (FR-017).

**Rationale**: Explicit out-of-scope per spec and all prior editorial redesign specs.
