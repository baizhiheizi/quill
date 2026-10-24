---
max-ai-credits: -1
engine:
  id: claude
  env:
    ANTHROPIC_API_KEY: ${{ secrets.MINIMAX_API_KEY }}
    ANTHROPIC_BASE_URL: "https://api.minimaxi.com/anthropic"
    ANTHROPIC_MODEL: "MiniMax-M3.1-Flash"
    API_TIMEOUT_MS: "3000000"
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"
    CLAUDE_CODE_AUTO_COMPACT_WINDOW: "512000"
models:
  providers:
    anthropic:
      models:
        MiniMax-M3.1-Flash:
          cost:
            input: 1.5e-7
            output: 6.0e-7
            cache_read: 1.5e-8
network:
  allowed:
    - defaults
    - api.minimaxi.com
---
