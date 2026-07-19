---
on:
  schedule: weekly on monday
  workflow_dispatch: null
permissions: read-all
network: defaults
imports:
- shared/engine-deepseek.md
safe-outputs:
  create-discussion:
    category: ideas
    title-prefix: "[weekly-research] "
  report-failure-as-issue: false
description: |
  This workflow performs research to  provides industry insights and competitive analysis.
  Reviews recent code, issues, PRs, industry news, and trends to create comprehensive
  research reports. Covers related products, research papers, market opportunities,
  business analysis, and new ideas. Creates GitHub discussions with findings to inform
  strategic decision-making.
runs-on:
- self-hosted
- linux
- agentic
runs-on-slim: self-hosted
source: githubnext/agentics/workflows/weekly-research.md@1c6668b751c51af8571f01204ceffb19362e0f66
timeout-minutes: 15
tools:
  github:
    min-integrity: none
    toolsets:
    - all
  web-fetch: null
---
# Weekly Research

## Job Description

Do a deep research investigation in ${{ github.repository }} repository, and the related industry in general.

- Read selections of the latest code, issues and PRs for this repo.
- Read latest trends and news from the software industry news source on the Web.

Create a new GitHub discussion with title starting with "[weekly-research]" containing a markdown report with

- Interesting news about the area related to this software project.
- Related products and competitive analysis
- Related research papers
- New ideas
- Market opportunities
- Business analysis
- Enjoyable anecdotes

Only a new discussion should be created, no existing discussions should be adjusted.

At the end of the report list write a collapsed section with the following:
- All search queries (web, issues, pulls, content) you used
- All bash commands you executed
- All MCP tools you used
