# Agents Guide

## Overview

The workspace provides 9 specialized agents, each running as an independent Claude Code instance in a tmux tab. Agents are defined in `configs/agents.conf`.

## Agent details

### Orchestrator (`orchestrateur`)
- **Model**: opus (most capable)
- **Role**: Central brain that decomposes projects, creates plans, coordinates other agents
- **Does NOT modify code** — plans and coordinates only
- **Use for**: New features, architecture decisions, complex tasks

### Backend Developer (`backend-dev`)
- **Model**: sonnet (balanced)
- **Role**: Implements REST APIs, business logic, WebSocket, database, auth
- **Use for**: API endpoints, data models, server-side logic

### Frontend Developer (`frontend-dev`)
- **Model**: sonnet (balanced)
- **Role**: Implements UI/UX, SPA components, responsive design, accessibility
- **Use for**: User interface, HTML/CSS/JS, mobile layouts

### System Administrator (`admin-sys`)
- **Model**: sonnet (balanced)
- **Role**: Infrastructure, networking, security, server configuration
- **Use for**: SSH, firewall, VPN, system monitoring

### DevOps (`devops`)
- **Model**: sonnet (balanced)
- **Role**: CI/CD, Docker, cloud deployment, Terraform, monitoring
- **Use for**: Build pipelines, container images, deployment, infra-as-code

### Tester (`testeur`)
- **Model**: haiku (fast, low cost)
- **Role**: Unit tests, integration tests, E2E tests, quality reports
- **Use for**: Writing and running tests after implementation

### Reviewer (`reviewer`)
- **Model**: sonnet (balanced)
- **Role**: Code review for quality and OWASP security
- **Does NOT modify code** — analyzes and reports only
- **Use for**: Security audits, code quality checks

### Stabilizer (`stabilizer`)
- **Model**: sonnet (balanced)
- **Role**: Verifies app stability: server start, build, tests, deploy
- **Always runs LAST** in the pipeline
- **Use for**: Final verification after each feature

### Manager (`manager`)
- **Model**: opus (most capable)
- **Role**: Project tracking, prioritization, conflict resolution, reports
- **Does NOT modify code** — analyzes and reports only
- **Use for**: Progress reports, prioritization, blocker detection

## Customization

### Change agent models

Edit `configs/agents.conf`:
```bash
AGENTS_DEF=(
  "orchestrateur|opus|Central brain"
  "backend-dev|sonnet|REST API specialist"
  # Change haiku to sonnet for a more capable tester:
  "testeur|sonnet|Unit tests, integration, E2E"
)
```

### Add a custom agent

Append to `configs/agents.conf`:
```bash
AGENTS_DEF+=(
  "security-auditor|opus|Security specialist, penetration testing"
)
```

Then add a system prompt in `scripts/07-launch-agents.sh` in the `get_system_prompt()` function.

### Launch specific agents

```bash
# Only orchestrator and backend
bash scripts/07-launch-agents.sh --project ~/workspace/my-project \
  --agents orchestrateur backend-dev

# List available agents
bash scripts/07-launch-agents.sh --list
```

### Remove an agent

Comment out its line in `configs/agents.conf`.

## Agent pipeline

The recommended execution order for features:

```
1. orchestrateur  → Plans and decomposes
2. backend-dev    → Implements backend
3. frontend-dev   → Implements frontend
4. admin-sys      → Infrastructure (if needed)
5. devops         → CI/CD, deploy (if needed)
6. testeur        → Writes and runs tests
7. reviewer       → Code review
8. stabilizer     → Final verification (ALWAYS LAST)
```
