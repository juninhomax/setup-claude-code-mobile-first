# Multi-agent team

## Available agents

### 1. Orchestrator (`/orchestrateur`)
- **Model** : claude-opus-4-6
- **Role** : Central brain. Decomposes projects, creates plans, coordinates agents, reviews outputs
- **When to use** : Complex new features, major refactoring, architecture decisions
- **Access** : Read-only (context: fork)
- **Responsibilities** :
  - Analyze the scope of a request
  - Decompose into ordered technical subtasks
  - Assign appropriate agents
  - Define execution order

### 2. Backend Dev (`/backend-dev`)
- **Model** : claude-sonnet-4-5-20250929
- **Role** : REST API, business logic, database, backend security
- **When to use** : API routes, WebSocket, store, auth, external API calls
- **Access** : Full write
- **Responsibilities** :
  - Implement API endpoints
  - Manage data store
  - Configure WebSocket broadcast
  - Secure routes (auth middleware)

### 3. Frontend Dev (`/frontend-dev`)
- **Model** : claude-sonnet-4-5-20250929
- **Role** : UI/UX, SPA components, responsive, accessibility
- **When to use** : User interface, HTML pages, JS interactions, CSS
- **Access** : Full write
- **Responsibilities** :
  - Mobile-first SPA interface
  - WebSocket client for real-time updates
  - UI components without framework
  - Accessibility and responsive design

### 4. Admin Sys/Network (`/admin-sys`)
- **Model** : claude-sonnet-4-5-20250929
- **Role** : Infrastructure, networking, system security, server configuration
- **When to use** : Server config, firewall, SSH, VPN, security
- **Access** : Full write
- **Responsibilities** :
  - System security (SSH, firewall, HTTPS)
  - Network configuration
  - System monitoring

### 5. DevOps (`/devops`)
- **Model** : claude-sonnet-4-5-20250929
- **Role** : CI/CD, containerization, monitoring, deployment
- **When to use** : Docker, cloud services, Terraform, CI/CD, monitoring
- **Access** : Full write
- **Responsibilities** :
  - Dockerfile and builds
  - Terraform infra
  - CI/CD pipelines
  - Cloud deployment
  - Health checks and monitoring

### 6. Tester (`/testeur`)
- **Model** : claude-haiku-4-5-20251001
- **Role** : Unit tests, integration, E2E, quality reports
- **When to use** : After each implementation, before stabilization
- **Access** : Full write (test files)
- **Responsibilities** :
  - Write tests (unit, integration, E2E)
  - Execute test suites
  - Report results

### 7. Reviewer (`/reviewer`)
- **Model** : claude-sonnet-4-5-20250929 (implicit)
- **Role** : Code review: quality + OWASP security
- **When to use** : After implementation, before merge
- **Access** : Read-only (context: fork)
- **Responsibilities** :
  - Quality and security review
  - OWASP issue detection
  - Improvement suggestions

### 8. Stabilizer (`/stabilizer`)
- **Model** : implicit
- **Role** : Build + tests + deploy verification
- **When to use** : ALWAYS last, after each feature
- **Access** : Full write (can fix)
- **Responsibilities** :
  - Verify syntax
  - Test server start
  - Validate build
  - Run tests
  - Fix issues found

### 9. Manager (`/manager`)
- **Model** : claude-opus-4-6
- **Role** : Project tracking, prioritization, conflict resolution, reports
- **When to use** : Progress updates, replanning, blockers
- **Access** : Read-only (context: fork)
- **Responsibilities** :
  - Progress reports
  - Task prioritization
  - Blocker detection

## Team composition rules

1. **Stabilizer ALWAYS last** in the pipeline
2. **Orchestrator ALWAYS first** (when assigned)
3. **Backend-dev or Frontend-dev** always present for code features
4. Execution order follows the assignment table in project.md
5. Read-only agents (orchestrator, reviewer, manager) don't block the pipeline
