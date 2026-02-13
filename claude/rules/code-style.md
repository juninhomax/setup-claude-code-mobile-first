---
paths:
  - "**/*.js"
  - "**/*.ts"
  - "**/*.html"
---

# Code style rules

- No console.log in production — use a logger or condition with NODE_ENV
- No commented-out code — delete it or create an issue
- Short, focused functions (< 50 lines)
- Explicit naming: no cryptic abbreviations
- Error handling: always try/catch on external API calls
- Security: validate all user inputs, no injection possible
- Frontend: mobile-first, responsive design
