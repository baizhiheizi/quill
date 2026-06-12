# Quill Documentation

Quill is a Web3 paid-publishing platform that builds a **value net** between authors and readers using an early-reader rewards mechanism. This documentation follows the [Diátaxis](https://diataxis.fr/) framework so each page has a single, predictable purpose.

## Where to start

| If you want to… | Read |
|------------------|------|
| Understand the value net and why Quill exists | [Explanation → Value net](./explanation/value-net.md) |
| See how the system fits together | [Explanation → Architecture](./explanation/architecture.md) |
| Set up a local development environment | [How-to → Set up local development](./how-to/local-development.md) |
| Create or update an article through the API | [Reference → HTTP API](./reference/api.md) |
| Look up a service object or background job | [Reference → Services](./reference/services.md), [Reference → Background jobs](./reference/background-jobs.md) |
| Look up a Noticed notifier or its delivery method | [Reference → Notifiers](./reference/notifiers.md) |
| Look up a frontend Stimulus controller | [Reference → Stimulus controllers](./reference/stimulus-controllers.md) |

## Documentation map

```
docs/
├── README.md                     # this file
├── explanation/                  # Understanding-oriented (Diátaxis: explanation)
│   ├── value-net.md              # the early reader rewards mechanism
│   └── architecture.md           # subsystem overview: web, dashboard, admin, API, jobs
├── how-to/                       # Problem-oriented (Diátaxis: how-to guides)
│   └── local-development.md      # bootstrap a working dev environment
├── reference/                    # Information-oriented (Diátaxis: reference)
│   ├── api.md                    # HTTP API surface (JSON endpoints)
│   ├── services.md               # app/services/* command/query objects
│   ├── background-jobs.md        # app/jobs/* ActiveJob classes
│   ├── notifiers.md              # app/notifiers/* Noticed 3 notifier classes
│   └── stimulus-controllers.md   # app/javascript/controllers/* — catalog + lifecycle patterns
└── tutorials/                    # Learning-oriented (Diátaxis: tutorials)
    └── (placeholder)             # guided walkthroughs will live here
```

## Conventions

- **Markdown only.** Pages use GitHub-flavored Markdown; no MDX or proprietary extensions.
- **Code samples must run.** Every snippet is checked against the codebase under `app/`, `config/`, or `bin/` before it is merged.
- **Progressive disclosure.** Each page opens with the 30-second summary, then drills into details.
- **Plain English, active voice.** Prefer the second person ("you can…") and the present tense.

## Cross-references

The repository's [README](../README.md) is the elevator pitch. The agent-facing context lives in [AGENTS.md](../AGENTS.md) at the repo root. Contributor onboarding is in [CONTRIBUTING.md](../CONTRIBUTING.md).

## Contributing

Documentation gaps are tracked as issues with the `documentation` label. To add a new page, copy the closest existing example and follow the [style notes above](#conventions). Open a draft pull request for review.