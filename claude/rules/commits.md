# Commit rules

- Atomic commits: one commit = one logical change
- **YOU MUST** use the format: `type(scope): short description`
  - `feat(scope): description` — new feature
  - `fix(scope): description` — bug fix
  - `refactor(scope): description` — refactoring without behavior change
  - `test(scope): description` — add or modify tests
  - `docs(scope): description` — documentation
  - `chore(scope): description` — maintenance, config
  - `deploy(scope): description` — deployment, infra
- The **scope** identifies the functional domain. Examples:
  - `(backend)` — Backend API
  - `(frontend)` — Frontend UI
  - `(auth)` — Authentication
  - `(ws)` — WebSocket
  - `(infra)` — Terraform / Cloud
  - `(docker)` — Dockerfile, container
  - `(ci)` — CI/CD pipelines
- Never commit .env files, secrets, or credentials
