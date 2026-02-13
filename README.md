# setup-claude-code-mobile-first

> Set up a complete Claude Code multi-agent workspace in 5 minutes, accessible from your iPhone.

## What you get

- **Secured server**: SSH hardening, UFW firewall, fail2ban, Tailscale VPN
- **Claude Code CLI**: installed and configured with your API key
- **9 specialized agents** in tmux tabs, each with its own model and system prompt
- **Web IDE**: code-server (VS Code in the browser)
- **Azure (optional)**: Terraform to provision the VM automatically

## Quick start (5 minutes)

### Prerequisites

- An Ubuntu 22.04+ server (VM, VPS, or local)
- An [Anthropic API key](https://console.anthropic.com) — **required to skip OAuth login on mobile**
- SSH access to the server

### 1. Clone and configure

```bash
git clone https://github.com/juninhomax/setup-claude-code-mobile-first.git
cd setup-claude-code-mobile-first
cp config.env.example config.env
nano config.env   # Set ANTHROPIC_API_KEY and WEB_PASSWORD (for code-server)
```

### 2. Run setup

```bash
sudo bash scripts/setup.sh
```

This runs all steps:
1. Bootstrap OS (packages, user, swap)
2. Node.js + Claude Code CLI
3. code-server (VS Code web)
4. _(agents launched manually)_
5. Validation

### 2b. Configure API key (skip OAuth)

```bash
# This is required for mobile access — skips the browser login entirely
bash scripts/setup-api-key.sh
```

> Without an API key, Claude Code will ask for OAuth login via a browser,
> which is very hard to complete on mobile. Always set your API key first.

### 3. Launch agents

```bash
# Copy the .claude/ template to your project
cp -r claude/ ~/workspace/my-project/.claude/

# Launch 9 agents
bash scripts/07-launch-agents.sh --project ~/workspace/my-project
```

### 4. Access from iPhone

| Service | URL | Auth |
|---------|-----|------|
| VS Code | `https://<IP>:8080/` | your WEB_PASSWORD |

## Agents

| Agent | Model | Role |
|-------|-------|------|
| orchestrateur | opus | Central brain — plans, coordinates, reviews |
| backend-dev | sonnet | REST API, business logic, WebSocket |
| frontend-dev | sonnet | UI/UX, SPA, responsive mobile-first |
| admin-sys | sonnet | Infrastructure, networking, security |
| devops | sonnet | CI/CD, Docker, cloud, Terraform |
| testeur | haiku | Unit/integration/E2E tests |
| reviewer | sonnet | Code review: quality + OWASP security |
| stabilizer | sonnet | Build, tests, deploy verification |
| manager | opus | Project tracking, prioritization |

## tmux navigation

| Shortcut | Action |
|----------|--------|
| `Ctrl+A, 1-9` | Go to agent N |
| `Ctrl+A, n` | Next agent |
| `Ctrl+A, p` | Previous agent |
| `Ctrl+A, w` | Tree view (all agents) |
| `Ctrl+A, d` | Detach (agents continue) |

## Selective install

```bash
# Skip Tailscale
sudo bash scripts/setup.sh --skip 3

# Only install Claude Code + agents
sudo bash scripts/setup.sh --only 4 7

# Start from step 5
sudo bash scripts/setup.sh --from 5
```

## Azure VM (optional)

If you don't have a server, provision one with Terraform:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars   # Set subscription_id, ssh key, etc.

terraform init
terraform plan
terraform apply
```

See [docs/TERRAFORM.md](docs/TERRAFORM.md) for details.

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — How the multi-agent system works
- [Mobile Access](docs/MOBILE-ACCESS.md) — iPhone/iPad setup guide
- [Agents](docs/AGENTS.md) — Detailed agent descriptions and customization
- [Terraform](docs/TERRAFORM.md) — Azure VM provisioning
- [Troubleshooting](docs/TROUBLESHOOTING.md) — Common issues and fixes

## Project structure

```
setup-claude-code-mobile-first/
├── README.md                    # This file
├── LICENSE                      # MIT
├── config.env.example           # Configuration template
├── scripts/                     # Installation scripts (01-08 + setup.sh)
├── configs/                     # tmux, agents, Caddyfile configs
├── claude/                      # .claude/ template for your projects
│   ├── settings.json            # Permissions + hooks
│   ├── board.md, team.md        # Coordination files
│   ├── hooks/                   # Pre/post hooks
│   ├── rules/                   # Code style, commits, branches
│   └── skills/                  # 9 agent skill definitions
├── terraform/                   # Optional Azure VM provisioning
└── docs/                        # Detailed documentation
```

## License

MIT
