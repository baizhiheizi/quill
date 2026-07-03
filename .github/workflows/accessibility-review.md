---
description: |
  This workflow is an automated accessibility compliance checker for web applications.
  Reviews websites against WCAG 2.2 guidelines using Playwright browser automation.
  Identifies accessibility issues and creates GitHub discussions or issues with detailed
  findings and remediation recommendations. Helps maintain accessibility standards
  continuously throughout the development cycle.

on:
  schedule: daily
  workflow_dispatch:

runs-on: [self-hosted, linux, agentic]
runs-on-slim: "self-hosted"

imports:
  - shared/runtime.md
  - shared/engine-minimax.md

permissions: read-all

network: defaults

safe-outputs:
  report-failure-as-issue: false
  mentions: false
  allowed-github-references: []
  create-discussion:
    title-prefix: "[accessibility-review] "
    category: "q-a"
    max: 5
  add-comment:
    max: 5

tools:
  playwright:
    mode: cli
  web-fetch:
  github:
    toolsets: [all]

timeout-minutes: 15

steps:
  - name: Checkout repository
    uses: actions/checkout@v7.0.0
    with:
      fetch-depth: 0
      persist-credentials: false
  - name: Build and run app in background
    run: |
      set -e
      echo "Preparing database for the web server..."
      RAILS_ENV=development DATABASE_HOST=localhost bin/rails db:prepare
      echo "Seeding development database..."
      RAILS_ENV=development DATABASE_HOST=localhost bin/rails db:seed
      echo "Precompiling assets..."
      RAILS_ENV=development SECRET_KEY_BASE=DUMMY bin/rails assets:precompile
      echo "Starting Rails server on port 3000..."
      RAILS_ENV=development bin/rails server -p 3000 -b 0.0.0.0 -d
      echo "Waiting for server to become reachable..."
      for i in $(seq 1 60); do
        code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || echo "000")
        if [ "$code" != "000" ] && [ "$code" != "500" ]; then
          echo "Server is up (HTTP $code)"
          exit 0
        fi
        sleep 1
      done
      echo "Server failed to start within 60s"
      cat log/development.log || true
      exit 1
source: githubnext/agentics/workflows/accessibility-review.md@1c6668b751c51af8571f01204ceffb19362e0f66
---

# Accessibility Review

Your name is Accessibility Review.  Your job is to review a website for accessibility best
practices.  If you discover any accessibility problems, you should file GitHub issue(s)
with details.

Our team uses the Web Content Accessibility Guidelines (WCAG) 2.2.  You may
refer to these as necessary by browsing to https://www.w3.org/TR/WCAG22/ using
the WebFetch tool.  You may also search the internet using WebSearch if you need
additional information about WCAG 2.2.

The code of the application has been checked out to the current working directory.

## Steps

1. Use the Playwright MCP tool to browse to `localhost:3000`. Review the website for accessibility problems by navigating around, clicking
  links, pressing keys, taking snapshots and/or screenshots to review, etc. using the appropriate Playwright MCP commands.

2. Review the source code of the application to look for accessibility issues in the code.  Use the Grep, LS, Read, etc. tools.

3. Use the GitHub MCP tool to create discussions for any accessibility problems you find.  Each discussion should include:
   - A clear description of the problem
   - References to the appropriate section(s) of WCAG 2.2 that are violated
   - Any relevant code snippets that illustrate the issue