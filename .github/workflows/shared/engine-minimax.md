---
max-ai-credits: -1
engine:
  id: claude
  env:
    ANTHROPIC_BASE_URL: "https://api.minimaxi.com/anthropic"
    ANTHROPIC_MODEL: "MiniMax-M3"
    API_TIMEOUT_MS: "3000000"
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"
    CLAUDE_CODE_AUTO_COMPACT_WINDOW: "512000"
models:
  providers:
    anthropic:
      models:
        MiniMax-M3:
          cost:
            input: 1.2e-6
            output: 4.8e-6
            cache_read: 2.4e-7
network:
  allowed:
    - defaults
    - api.minimaxi.com
---
