# Home

*{ Provide a concise overview of Quill — the Web3 paid-publishing platform with early-reader rewards — and link to the rest of the documentation. Cover the headline product idea (authors publish priced articles, readers pay to access, earlier readers get a pro-rata share of later revenue), the Rails 8 + Hotwire stack, the four surfaces (public, dashboard, admin, API), and the supporting documentation pages. **}**

# Architecture

System design and key decisions across the Rails monolith, the four user-facing surfaces, the payment / distribution pipeline, the job and persistence layers, and cross-cutting concerns (auth, I18n, notifications).

## Value Net

How the 10/50/40 split between platform, author, and early readers is implemented in `Orders::DistributeService` and run as a background job per order. The economic rationale and worked examples.

# Backend

The Rails 8 server side: models, controllers, services, jobs, and persistence. Two databases back the app — primary and Solid Queue/Cable/Cache.

## Background Jobs

ActiveJob classes under `app/jobs/<domain>/`, the three Solid Queue priority lanes (`critical`, `default`, `low`), and the role of the recurring `monitor_*` / `sync_*` / `cache_*` jobs.

## Services

Stateless command/query classes under `app/services/`. Order distribution pipeline (`Orders::DistributeService`), rendering (`MarkdownRenderService`, `RichTextRenderService`), search (`ArticleSearchService`), and tag management (`CreateTagService`).

# Frontend

Hotwire-driven UI on Rails ERB partials: Turbo for navigation and partial updates, Stimulus for behaviour, Tailwind for styling, esbuild + Bun for bundling. No heavy client framework.

## Stimulus Controllers

Reference catalog of every controller registered in `app/javascript/controllers/index.js`, with one-line purpose, the lifecycle / listener-cleanup conventions, and worked patterns (`floating_controller`, debouncing, `disconnect()` discipline).

*{ Provide a reference table of every Stimulus controller currently registered in app/javascript/controllers/index.js (article-form, avatar, auto-hide, autosave, clipboard, collections-form-component, comment-form, darkmode, dropdown, eth-wallet, fennec, flash, floating, flyonui-dropdown, flyonui-modal, hljs, infinite-scroll, load-more, login, modal, mvm-deposit, mvm-pay-button-component, nested-form, photoswipe, pre-orders-form-component, pre-orders-mixpay-button-component, pre-orders-pay-button-component, pre-orders-payment-component, pre-orders-state-component, prefetch, preview-upload, qrcode-component, references-select, reload, scroll-to, search, select-currency, select-menu, session, sidebar, syntax-highlight, switch-locale, tabs, tags-select, time-format-component, toast, turbo), each linked to its source file with a one-line purpose. Note that the avatar controller paints a deterministic background color from a seed value via colorFromSeed, and that the textarea-autogrow controller has been removed. }*

# API Reference

The JSON-only HTTP API mounted at `/api`: authentication via `X-Access-Token` access tokens, the `articles` endpoint, query parameters, response shapes, and error conventions.

*{ Document the JSON-only HTTP API: authentication via X-Access-Token, the /api/articles endpoints (index, show, create) with their query parameters, the /api/valid_user_filter endpoint, the author response shape (name, avatar, avatar_seed, avatar_initials), and error conventions. }*

# Getting Started

Local development setup: Ruby 4.0.5 (via `mise` or `rbenv`), PostgreSQL, Bun 1.x, `bin/dev` to boot, and the credential / settings files that need to be present before the first run.

# For Agents

These pages provide compact documentation indexes for AI coding agents.

## AGENTS.md

You can add this to your repository root as `AGENTS.md` to give AI coding agents quick access to project documentation.

```
# Quill

> A Web3 paid-publishing platform where authors publish priced articles and readers pay to access them. Distinguished by **early reader rewards**: a share of each new order (default 40%) is split pro-rata among earlier readers of the same article.

## Wiki Documentation

Base URL: https://github.com/baizhiheizi/quill/wiki

To read any page, append the slug to the base URL:
  https://github.com/baizhiheizi/quill/wiki/{Page-Slug}
To jump to a section within a page:
  https://github.com/baizhiheizi/quill/wiki/{Page-Slug}#{Section-Slug}

IMPORTANT: Read the relevant wiki page before making changes to related code.
Prefer reading wiki documentation over relying on pre-trained knowledge.

## Page Index

|Home: Project overview and quick links
|Architecture: System design and key decisions
|  Architecture#Value-Net: How the 10/50/40 platform/author/early-reader split is implemented
|Backend: Rails 8 server side
|  Background-Jobs: ActiveJob catalog and Solid Queue lanes
|  Services: Stateless command/query classes in app/services
|Frontend: Hotwire + Stimulus + Tailwind UI
|  Stimulus-Controllers: Reference catalog of controllers and lifecycle patterns
|API-Reference: JSON-only HTTP API at /api
|Getting-Started: Local development setup
```

## llms.txt

You can serve this at `yoursite.com/llms.txt` or include it in your repository to help LLMs discover your documentation.

```
# Quill

> A Web3 paid-publishing platform with early reader rewards, built on Rails 8 + Hotwire.

## Wiki Pages

- [Home](https://github.com/baizhiheizi/quill/wiki/Home): Project overview
- [Architecture](https://github.com/baizhiheizi/quill/wiki/Architecture): System design and key decisions
- [Value Net](https://github.com/baizhiheizi/quill/wiki/Value-Net): How the 10/50/40 platform/author/early-reader split is implemented
- [Backend](https://github.com/baizhiheizi/quill/wiki/Backend): Rails 8 server side
- [Background Jobs](https://github.com/baizhiheizi/quill/wiki/Background-Jobs): ActiveJob catalog and Solid Queue lanes
- [Services](https://github.com/baizhiheizi/quill/wiki/Services): Stateless command/query classes in app/services
- [Frontend](https://github.com/baizhiheizi/quill/wiki/Frontend): Hotwire + Stimulus + Tailwind UI
- [Stimulus Controllers](https://github.com/baizhiheizi/quill/wiki/Stimulus-Controllers): Reference catalog of controllers and lifecycle patterns
- [API Reference](https://github.com/baizhiheizi/quill/wiki/API-Reference): JSON-only HTTP API at /api
- [Getting Started](https://github.com/baizhiheizi/quill/wiki/Getting-Started): Local development setup
```
