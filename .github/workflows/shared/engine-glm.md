---
max-ai-credits: -1
engine:
  id: claude
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ZHIPU_API_KEY }}
    ANTHROPIC_BASE_URL: "https://open.bigmodel.cn/api/anthropic"
    ANTHROPIC_MODEL: "glm-5.3-flash[1m]"
    CLAUDE_CODE_AUTO_COMPACT_WINDOW: "1000000"
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"
    API_TIMEOUT_MS: "3000000"
models:
  providers:
    anthropic:
      models:
        glm-5.3-flash:
          cost:
            input: 1.2e-7
            output: 4.2e-7
            cache_read: 3.4e-8
network:
  allowed:
    - defaults
    - api.minimaxi.com
    - open.bigmodel.cn
---
