---
max-ai-credits: -1
engine:
  id: claude
  env:
    ANTHROPIC_API_KEY: ${{ secrets.DEEPSEEK_API_KEY }}
    ANTHROPIC_BASE_URL: "https://api.deepseek.com/anthropic"
    ANTHROPIC_MODEL: "deepseek-flash"
    # CLAUDE_CODE_EFFORT_LEVEL: "max"
    API_TIMEOUT_MS: "3000000"
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"
models:
  providers:
    anthropic:
      models:
        deepseek-flash:
          cost:
            input: 3e-7
            output: 1.2e-6
            cache_read: 6e-9
network:
  allowed:
    - defaults
    - api.deepseek.com
---
