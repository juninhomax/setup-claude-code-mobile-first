---
paths:
  - "**/*.js"
  - "**/*.ts"
  - "**/*.html"
  - "**/Dockerfile"
  - "**/*.tf"
---

# Stability rules

- IMPORTANT: After any code modification, run /stabilizer or manually verify:
  1. Server/app starts without error
  2. Key API endpoints respond correctly
  3. Build passes (Docker, CI, etc.)
- Never disable an existing test to "make it pass"
- Each feature must be stable BEFORE moving to the next
- After deploy, always verify the health check endpoint
