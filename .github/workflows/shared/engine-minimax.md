---
engine:
  id: claude
  env:
    ANTHROPIC_BASE_URL: "https://api.minimaxi.com/anthropic"
    ANTHROPIC_MODEL: "MiniMax-M2.7-highspeed"
    API_TIMEOUT_MS: 3000000
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: 1
network:
  allowed:
    - defaults
    - api.minimaxi.com
---
