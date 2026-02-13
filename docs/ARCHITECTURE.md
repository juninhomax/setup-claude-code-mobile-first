# Architecture

## Overview

The multi-agent workspace is a tmux-based system where each tmux tab runs an independent Claude Code instance with a specialized system prompt. Agents coordinate through a shared `board.md` file and Git.

```
┌─────────────────────────────────────────────────┐
│                 ORCHESTRATOR                      │
│              (claude-opus-4-6)                    │
│  Decomposes, plans, coordinates, reviews         │
├─────────────────────────────────────────────────┤
│                                                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │ Backend  │ │ Frontend │ │ Admin Sys/Net    │ │
│  │   Dev    │ │   Dev    │ │                  │ │
│  │ (sonnet) │ │ (sonnet) │ │    (sonnet)      │ │
│  └──────────┘ └──────────┘ └──────────────────┘ │
│                                                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │  DevOps  │ │ Tester   │ │    Manager       │ │
│  │ (sonnet) │ │ (haiku)  │ │    (opus)        │ │
│  └──────────┘ └──────────┘ └──────────────────┘ │
│                                                   │
│  ┌──────────┐ ┌──────────┐                       │
│  │ Reviewer │ │Stabilizer│                       │
│  │ (sonnet) │ │ (sonnet) │                       │
│  └──────────┘ └──────────┘                       │
└─────────────────────────────────────────────────┘
```

## How agents coordinate

1. **Shared board** (`.claude/board.md`): Each agent reads and writes to this file. The orchestrator writes the plan and task assignments. Other agents update their progress.

2. **Git**: All agents work on the same Git repository. They can see each other's commits and changes.

3. **System prompts**: Each agent has a specialized prompt that defines its role, rules, and mission. Prompts are injected via `claude --append-system-prompt`.

4. **Skills**: Claude Code skills (`.claude/skills/`) provide structured commands that agents can invoke with `/skill-name`.

## tmux session structure

```
claude-agents (tmux session)
├── 1: orchestrateur  (claude opus)
├── 2: backend-dev    (claude sonnet)
├── 3: frontend-dev   (claude sonnet)
├── 4: admin-sys      (claude sonnet)
├── 5: devops         (claude sonnet)
├── 6: testeur        (claude haiku)
├── 7: reviewer       (claude sonnet)
├── 8: stabilizer     (claude sonnet)
├── 9: manager        (claude opus)
└── 10: monitor       (watch: git status + board)
```

## Web access layer

```
iPhone Safari
    │
    ▼
┌─────────────┐
│   Caddy     │ (reverse proxy, auto-TLS)
│  :443       │──────► ttyd :7681 (web terminal)
│  :8080      │──────► code-server :8443 (VS Code)
└─────────────┘
```

- **ttyd**: Lightweight web terminal. Connects to the tmux session so you can switch between agents.
- **code-server**: Full VS Code in the browser. Edit files, run terminals, use extensions.
- **Caddy**: Handles HTTPS (Let's Encrypt or self-signed) and reverse proxies.

## Security model

- SSH: key-only auth, root disabled, fail2ban
- Firewall: UFW with minimal open ports
- VPN: Tailscale (optional, zero-trust)
- Web services: password-protected via ttyd credentials
- API keys: stored in `~/.claude-env` with 600 permissions

## Workflow

See [claude/workflow.md](../claude/workflow.md) for the full feature workflow:

```
[task] -> [in-progress] -> [implement] -> [stabilize] -> [done] -> [clean]
```
