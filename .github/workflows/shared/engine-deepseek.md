---
max-ai-credits: -1
engine:
  id: claude
  env:
    ANTHROPIC_API_KEY: ${{ secrets.DEEPSEEK_API_KEY }}
    ANTHROPIC_BASE_URL: "https://api.deepseek.com/anthropic"
    ANTHROPIC_MODEL: "deepseek-v4-flash"
    # CLAUDE_CODE_EFFORT_LEVEL: "max"
    API_TIMEOUT_MS: "3000000"
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"
models:
  providers:
    anthropic:
      models:
        deepseek-v4-flash:
          cost:
            input: 1.4e-7
            output: 2.8e-7
            cache_read: 2.8e-9
network:
  allowed:
    - defaults
    - api.deepseek.com
---
