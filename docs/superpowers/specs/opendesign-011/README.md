# Quill — OpenDesign snapshot (specs/011-comprehensive-ui-refactor)

This directory holds the visual source-of-truth for the Quill value-net redesign.
It was copied once from the live OpenDesign project `f69be881-fe22-4183-87c7-4cb7179540ff`
("Quill 界面重设计规划") so the design direction is reviewable, diffable, and
immutable from this repo.

## Contents

| File | Purpose |
|---|---|
| `brand-spec.md` | Six OKLCh tokens + Newsreader / Inter / Roboto Mono type stack + 8pt spacing scale + brand rules |
| `style.css` | The complete prototype stylesheet — every token + utility the OpenDesign HTML uses |
| `index.html` | Landing / launch page |
| `feed.html` | Home feed (the dense scannable list) |
| `search.html` | Search results |
| `author-profile.html` | Public author profile header + articles list |
| `collection.html` | Curated series page |
| `reader.html` | Article reader (paywall fade, unlock card, sticky support rail) |
| `editor.html` | Article editor (toolbar, pricing, reward split) |
| `dashboard.html` | Author studio (left-rail shell, stat cards, split calculator) |
| `components.html` | Component library (live in-prototype documentation) |

## Status

The live source-of-truth is the OpenDesign project. This snapshot is a frozen
reference for `specs/011-comprehensive-ui-refactor/` — do not edit these files
in place; if the design evolves, copy the new versions into this directory in a
new commit.