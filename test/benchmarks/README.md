# Benchmarks

Lightweight, stdlib-only timing harness for known hot paths. Uses test fixtures so results are reproducible on any machine with a prepared test database.

## Run

```bash
bin/benchmark                    # all scenarios
bin/benchmark article_search     # name substring filter
```

Optional env vars:

| Variable | Default | Purpose |
|----------|---------|---------|
| `BENCHMARK_WARMUP` | 2 | Discarded iterations before measuring |
| `BENCHMARK_ITERATIONS` | 5 | Measured iterations (mean/min/max reported) |

Example:

```bash
BENCHMARK_ITERATIONS=10 bin/benchmark article_search.bought
```

## Scenarios

| Name | Hot path |
|------|----------|
| `article_search.popularity` | Default feed (`order_by_popularity`) |
| `article_search.bought` | Purchased-articles filter |
| `article_search.subscribed` | Subscribed-authors filter |
| `article.random_readers` | SQL-sampled reader avatars |

## Limitations

- Fixture data is small; absolute milliseconds are **not** production representative.
- Use for **relative** before/after comparisons on the same machine (e.g. after a query optimization).
- Not run in CI by default. A future optional smoke job with `benchmark-ips` and thresholds is out of scope for v1.

## Adding scenarios

1. Register in `hot_paths.rb` with `Benchmarks::Runner.register("name") { ... }`.
2. Optional one-time setup: `Benchmarks::Runner.setup("name") { ... }` (must match a registered name).
