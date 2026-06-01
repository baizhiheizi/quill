---
engine:
  id: copilot
  env:
    COPILOT_PROVIDER_BASE_URL: "https://api.z.ai/api/anthropic"
    COPILOT_MODEL: "glm-5.1"
    COPILOT_PROVIDER_BEARER_TOKEN: ${{ secrets.ZAI_API_KEY }}
    COPILOT_PROVIDER_TYPE: anthropic
network:
  allowed:
    - defaults
    - api.z.ai
---
