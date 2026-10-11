---
# Runner requirement: every self-hosted Linux runner used by `repo-assist` must
# have Ruby 4.0.5 pre-installed at /opt/hostedtoolcache/Ruby/4.0.5/x64/bin.
# `ruby/setup-ruby@v1` falls back to installing Ruby on its own only when the
# runner user can `mkdir /opt/hostedtoolcache`; on the gh-sr container runners
# the directory is not writable, so without the pre-baked path the agent job
# fails with
#   ##[error]Error: EACCES: permission denied, mkdir '/opt/hostedtoolcache'
# (`Setup Ruby` step in repo-assist.lock.yml).
runtimes:
  ruby:
    version: "4.0.5"
  bun:
    version: "1.3.14"

# Why services carry NO port mappings, and how the agent reaches them:
#
# gh-aw >= v0.88 compiles every sandbox runtime with AWF network isolation:
# the agent container sits on the internal `awf-net` bridge (internal: true,
# no route to the runner host) and its only egress is the squid HTTP proxy.
# Under that topology the documented `services:` + host.docker.internal +
# `sandbox.agent.runtime: docker-sudo-iptables` pattern is inert on DinD /
# container runners (gh-sr, ARC): gh-aw still writes isolation:true for that
# profile, so the legacy iptables host-access path never engages
# (gh-aw#52140, gh-aw-firewall#7266 closed not-planned). The strict-mode
# validator also rejects services with published ports unless that runtime is
# selected — hence no `ports:` here.
#
# Instead this uses the gh-aw#57988 pattern, verified on the gh-sr runners:
# a pre-step joins this job's service containers to `awf-net` (the network
# AWF pins by name precisely so trusted external containers can be attached
# with `docker network connect`), reusing the service keys as DNS aliases.
# The sandboxed agent then resolves `postgres` / `redis` via Docker's
# embedded DNS and speaks native TCP — no host route, no iptables, default
# rootless runtime. Security note: the service gains an interface on the
# agent's internal network only (no egress from it); it keeps its original
# runner-network interface, which is the same trust already granted by
# declaring it under `services:`.
#
# When gh-sr's `awf_service_bridge` (or an upstream `services.<name>.attach`)
# is available, the joiner step below can be deleted.

env:
  DATABASE_HOST: postgres
  REDIS_URL: redis://redis:6379/15
  RAILS_ENV: test

services:
  postgres:
    image: pgvector/pgvector:pg16-trixie
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    options: >-
      --health-cmd="pg_isready -U postgres"
      --health-interval=10s
      --health-timeout=5s
      --health-retries=5
  redis:
    image: redis:7-alpine
    options: >-
      --health-cmd="redis-cli ping"
      --health-interval=10s
      --health-timeout=5s
      --health-retries=5

pre-agent-steps:
  # awf-net is created by AWF inside the agent step — after pre-agent steps —
  # so the join runs from a detached waiter (gh-aw#57988 pattern).
  - name: Join service containers to the AWF topology network
    run: |
      nohup bash -c '
        set -u
        log() { echo "[svc-join] $*"; }
        for i in $(seq 1 300); do
          docker network inspect awf-net >/dev/null 2>&1 && break
          sleep 2
        done
        docker network inspect awf-net >/dev/null 2>&1 || { log "awf-net never appeared"; exit 1; }
        NET=$(docker network ls --format "{{.Name}}" | grep "^github_network_" | tail -1)
        [ -n "$NET" ] || { log "no github_network found"; exit 1; }
        docker network inspect -f "{{range .Containers}}{{.Name}} {{end}}" "$NET" | tr " " "\n" | while read -r c; do
          [ -n "$c" ] || continue
          case "$(docker inspect -f "{{.Config.Image}}" "$c")" in
            *postgres*|*pgvector*) alias_name=postgres ;;
            *redis*) alias_name=redis ;;
            *) continue ;;
          esac
          if docker network connect --alias "$alias_name" awf-net "$c" 2>/dev/null; then
            log "joined $c as $alias_name"
          else
            log "skip $c (already attached or failed)"
          fi
        done
      ' > "${RUNNER_TEMP}/svc-join.log" 2>&1 &
      disown

  - name: Install Ruby gems
    run: bundle install --jobs 4 --retry 3

  - name: Install node modules
    run: bun install --frozen-lockfile

  - name: Set up database schema
    # The services publish no ports, so from the runner (the inner docker
    # host) reach postgres by its container IP; inside the sandbox
    # DATABASE_HOST=postgres resolves via awf-net.
    run: |
      NET=$(docker network ls --format '{{.Name}}' | grep '^github_network_' | tail -1)
      PG_CID=$(docker network inspect -f '{{range .Containers}}{{.Name}} {{end}}' "$NET" | tr ' ' '\n' | while read -r c; do
        case "$(docker inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)" in *pgvector*|*postgres*) echo "$c"; break ;; esac
      done)
      PG_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$PG_CID" | awk '{print $1}')
      echo "postgres container: $PG_CID at $PG_HOST"
      DATABASE_HOST="$PG_HOST" bin/rails db:prepare
---
