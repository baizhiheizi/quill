---
max-ai-credits: -1
engine:
  id: claude
  env:
    ANTHROPIC_API_KEY: ${{ secrets.DEEPSEEK_API_KEY }}
    ANTHROPIC_BASE_URL: "https://api.deepseek.com/anthropic"
    ANTHROPIC_MODEL: "deepseek-v4-flash"
    # CLAUDE_CODE_EFFORT_LEVEL: "max"
models:
  providers:
    anthropic:
      models:
        deepseek-v4-flash:
          cost:
            input: 0.14
            output: 0.28
            cache_read: 0.0028
network:
  allowed:
    - defaults
    - api.deepseek.com
---
