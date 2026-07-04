<!--
Sync Impact Report
- Version change: (template placeholders) → 1.0.0
- Modified principles: N/A (initial ratification)
- Added sections:
  - I. Code Quality & Rails Conventions
  - II. Testing Standards
  - III. User Experience Consistency
  - IV. Performance Requirements
  - Additional Constraints (Web3 & Domain Integrity)
  - Development Workflow & Quality Gates
  - Governance
- Removed sections: Generic spec-kit placeholder principles (Library-First, CLI Interface, etc.)
- Templates:
  - ✅ .specify/templates/plan-template.md (Constitution Check gates)
  - ✅ .specify/templates/tasks-template.md (testing alignment)
  - ✅ .specify/templates/spec-template.md (constitution alignment note)
  - ⚠ .specify/templates/commands/*.md (not present in repo)
- Follow-up TODOs: none
-->

# Quill Constitution

## Core Principles

### I. Code Quality & Rails Conventions

All changes MUST follow established Rails and Quill patterns. Ruby files MUST include
`# frozen_string_literal: true`. Naming MUST use snake_case for files/methods and
PascalCase for classes. Controllers, models, jobs, services, and notifiers MUST live in
their conventional directories under `app/`.

Business logic MUST prefer extending existing models, concerns, services, and jobs over
creating parallel implementations. Service objects MUST expose a `.call` factory method.
Views MUST reuse partials and `UiHelper` block/slot wrappers (`render_modal`,
`render_dropdown`, etc.) before introducing new UI abstractions.

Diffs MUST stay focused: no drive-by refactors, unrelated formatting, or scope creep.
Before merge, `bin/rubocop` MUST pass for touched Ruby and `bun run lint-check` MUST
pass for touched JavaScript. Secrets (`master.key`, `settings.local.yml`, credential
values) MUST NEVER be committed.

**Rationale**: Quill is a mature Rails monolith; consistency reduces review cost, prevents
regressions in payment and revenue flows, and keeps agent/human contributors aligned.

### II. Testing Standards

Non-trivial behavior MUST have automated tests in `test/`, mirroring `app/` structure
(models, controllers, jobs, notifiers). Tests MUST assert real behavior—state changes,
authorization, revenue distribution, payment side effects—not trivial presence checks.

The full suite MUST pass locally (`bin/rails test`) and in CI before merge. Autoloading
MUST be verified (`bin/rails zeitwerk:check`) when adding or renaming constants.
Notifier tests MUST use `NotifierHelpers#deliver_notifier!` and assert on
`Noticed::Event` / `Noticed::Notification` records.

New features MUST include tests covering happy path and meaningful failure/edge cases
relevant to the change. Tests MAY be omitted only for purely presentational tweaks with
no behavioral impact; that omission MUST be stated in the PR or plan.

**Rationale**: Quill handles money movement and revenue sharing; untested changes risk
financial and trust failures that are expensive to diagnose in production.

### III. User Experience Consistency

User-facing surfaces—public site, author dashboard, admin, and API error payloads—MUST
feel cohesive. Interactive UI MUST use Hotwire (Turbo + Stimulus), Tailwind utility
classes, and existing ERB partials before bespoke markup or one-off CSS.

New copy MUST use i18n locale files (`config/locales/`) for user-visible strings; hard-
coded English in views is NOT acceptable for new UI. Forms, modals, dropdowns, and flash
feedback MUST follow patterns already used in neighboring screens.

Accessibility MUST meet baseline expectations: semantic HTML, keyboard-operable controls,
visible focus states, and sufficient color contrast on interactive elements. Destructive
or payment actions MUST include clear confirmation and error recovery paths.

API responses MUST follow existing JSON helpers and error shapes in `API::BaseController`
and `API::RenderingHelper`; clients MUST NOT receive ad-hoc payload structures.

**Rationale**: Quill serves authors, readers, and admins across multiple namespaces;
inconsistent UX erodes trust, especially around paid content and crypto payments.

### IV. Performance Requirements

Hot paths—article discovery/search, article show, checkout/payment, order distribution,
and background settlement—MUST NOT regress without measurement and justification. Database
access on these paths MUST avoid N+1 queries; use eager loading, scoped queries, or
service objects designed for batch access.

CPU- or IO-heavy work MUST run in Solid Queue jobs (`bin/jobs`), not synchronous web
requests, unless latency requirements are explicitly documented and approved. Cache reads
via Solid Cache MUST be considered for repeated, read-heavy aggregates when correctness
allows.

Performance-sensitive changes MUST be validated with `bin/benchmark` when touching search,
order, or transfer logic. Regressions beyond 10% on an existing benchmark scenario MUST
be fixed or documented in the plan's Complexity Tracking table with rejected alternatives.

Frontend assets MUST stay lean: prefer Stimulus targets/actions over heavy JS bundles; avoid
blocking render on non-critical scripts.

**Rationale**: Reader and author flows are latency-sensitive; payment backlog or slow
pages directly affect conversion and revenue distribution timeliness.

## Additional Constraints (Web3 & Domain Integrity)

Revenue split defaults and distribution logic (early readers ~40%, platform ~10%, author
remainder) MUST remain mathematically consistent unless a spec explicitly changes ratios
and includes migration/backfill tasks.

Payment integrations (Mixin OAuth, MixPay, Mixin bot notifiers) MUST reuse existing
integration points; new rails require security review and encrypted credential storage.

The launch gate (`ApplicationController#ensure_launched!`) and paid-content access rules
MUST be preserved unless the feature spec explicitly changes launch or access policy.

## Development Workflow & Quality Gates

Every feature plan MUST complete the Constitution Check in `plan-template.md` before
Phase 0 research and again after Phase 1 design. Pull requests MUST verify:

1. Lint clean (`bin/rubocop`, `bun run lint-check` as applicable)
2. Tests pass (`bin/rails test`, `bin/rails zeitwerk:check`)
3. UX reuse documented for any new UI (partials, Stimulus controllers, locales)
4. Performance impact noted for hot-path or job changes; benchmarks run when required

Complexity that violates a principle MUST be recorded in the plan's Complexity Tracking
table with a rejected simpler alternative.

Runtime development guidance lives in `AGENTS.md`; where `AGENTS.md` and this
constitution conflict, this constitution wins until amended.

## Governance

This constitution is the authoritative governance document for Quill feature work under
the Spec Kit workflow. Amendments MUST be made via `/speckit.constitution`, which updates
this file, bumps `CONSTITUTION_VERSION` semantically, and propagates changes to dependent
templates.

**Amendment procedure**:

1. Propose change with rationale and version bump type (MAJOR/MINOR/PATCH)
2. Update `.specify/memory/constitution.md` and sync dependent templates
3. Record changes in the Sync Impact Report HTML comment at the top of this file

**Versioning policy**:

- MAJOR: Principle removal or backward-incompatible redefinition
- MINOR: New principle or materially expanded guidance
- PATCH: Clarifications and non-semantic wording fixes

**Compliance review**: `/speckit.plan`, `/speckit.tasks`, and `/speckit.analyze` MUST
reference applicable principles. Reviewers SHOULD block merges when gates fail without
documented justification.

**Version**: 1.0.0 | **Ratified**: 2026-07-04 | **Last Amended**: 2026-07-04
