# Branch rules

- **YOU MUST** name branches with the format: `type/scope/short-description`
  - `feat/agents/real-time-status`
  - `fix/orchestrator/task-decomposition`
  - `refactor/backend/extract-ws-handler`
  - `deploy/infra/upgrade-vm`
- The **scope** in the branch name should match the commit scope
- Description in kebab-case (words separated by hyphens)
- No uppercase, no spaces, no special characters

# Pull Request rules

- **YOU MUST** name PRs with the format: `type(scope): short description`
  - Same format as commits
  - The PR title summarizes all changes in the branch
- The PR body must contain:
  - `## Summary` — 1 to 3 bullet points describing the changes
  - `## Test plan` — verification checklist
- The PR scope should match the branch and commit scopes
