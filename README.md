# setup-claude-code-mobile-first

> Installe un workspace Claude Code multi-agents en 5 minutes, accessible depuis ton iPhone.

## Ce que tu obtiens

- **Serveur sécurisé** : SSH hardening, UFW firewall, Tailscale VPN (optionnel)
- **Claude Code CLI** : installé via npm avec ta clé API
- **9 agents spécialisés** dans des onglets tmux, chacun avec son modèle et son prompt système
- **code-server** : VS Code dans le navigateur (`0.0.0.0:8080`)
- **Azure (optionnel)** : Terraform pour provisionner la VM automatiquement

## Quick start (5 minutes)

### Prérequis

- Un serveur Ubuntu 22.04+ (VM, VPS ou local)
- Une [clé API Anthropic](https://console.anthropic.com) — **obligatoire pour contourner le login OAuth sur mobile**
- Un accès SSH au serveur

### 1. Cloner et configurer

```bash
git clone https://github.com/juninhomax/setup-claude-code-mobile-first.git
cd setup-claude-code-mobile-first
cp config.env.example config.env
nano config.env   # Renseigner ANTHROPIC_API_KEY et WEB_PASSWORD
```

### 2. Lancer le setup

```bash
sudo bash scripts/setup.sh
```

Le script exécute dans l'ordre :
1. Bootstrap OS (paquets, utilisateur, swap)
2. Node.js 20 + Claude Code CLI
3. code-server (VS Code web sur le port 8080)
4. Validation

### 3. Configurer la clé API (obligatoire sur mobile)

```bash
bash scripts/setup-api-key.sh
```

> Sans clé API, Claude Code demande un login OAuth via navigateur,
> quasi impossible sur mobile. Toujours configurer la clé en premier.

### 4. Lancer les agents

```bash
# Copier le template .claude/ dans ton projet
cp -r claude/ ~/workspace/mon-projet/.claude/

# Lancer les 9 agents
bash scripts/07-launch-agents.sh --project ~/workspace/mon-projet
```

### 5. Accéder depuis l'iPhone

| Service | URL | Auth |
|---------|-----|------|
| VS Code | `http://<IP>:8080/` | WEB_PASSWORD |

## Agents

| Agent | Modèle | Rôle |
|-------|--------|------|
| orchestrateur | opus | Cerveau central — planifie, coordonne, review |
| backend-dev | sonnet | API REST, logique métier, WebSocket |
| frontend-dev | sonnet | UI/UX, SPA, responsive mobile-first |
| admin-sys | sonnet | Infra, réseau, sécurité |
| devops | sonnet | CI/CD, Docker, cloud, Terraform |
| testeur | haiku | Tests unitaires/intégration/E2E |
| reviewer | sonnet | Code review : qualité + sécurité OWASP |
| stabilizer | sonnet | Vérification build, tests, deploy |
| manager | opus | Suivi projet, priorisation |

## Navigation tmux

| Raccourci | Action |
|-----------|--------|
| `Ctrl+A, 1-9` | Aller à l'agent N |
| `Ctrl+A, n` | Agent suivant |
| `Ctrl+A, p` | Agent précédent |
| `Ctrl+A, w` | Vue arborescente (tous les agents) |
| `Ctrl+A, d` | Détacher (les agents continuent) |

## Installation sélective

```bash
# Sauter Tailscale
sudo bash scripts/setup.sh --skip 3

# Installer uniquement Claude Code + agents
sudo bash scripts/setup.sh --only 4 7

# Reprendre à partir de l'étape 5
sudo bash scripts/setup.sh --from 5
```

## Azure VM (optionnel)

Si tu n'as pas de serveur, provisionnes-en un avec Terraform :

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars   # Renseigner subscription_id, clé SSH, etc.

terraform init
terraform plan
terraform apply
```

Voir [docs/TERRAFORM.md](docs/TERRAFORM.md) pour les détails.

## Documentation

- [Procédure complète](docs/PROCEDURE.md) — Guide pas-à-pas (FR)
- [Architecture](docs/ARCHITECTURE.md) — Fonctionnement du système multi-agents
- [Accès mobile](docs/MOBILE-ACCESS.md) — Guide iPhone/iPad
- [Agents](docs/AGENTS.md) — Description détaillée et personnalisation
- [Terraform](docs/TERRAFORM.md) — Provisionnement VM Azure
- [Troubleshooting](docs/TROUBLESHOOTING.md) — Problèmes courants et solutions

## Structure du projet

```
setup-claude-code-mobile-first/
├── README.md                    # Ce fichier
├── LICENSE                      # MIT
├── config.env.example           # Template de configuration
├── scripts/
│   ├── setup.sh                 # Script principal (orchestrateur)
│   ├── 01-bootstrap.sh          # Paquets OS, utilisateur, swap
│   ├── 04-install-claude-code.sh # Node.js 20 + Claude Code CLI
│   ├── 06-install-code-server.sh # VS Code web (port 8080)
│   ├── 07-launch-agents.sh      # Lance 9 agents dans tmux
│   ├── 08-validate.sh           # Vérifie que tout fonctionne
│   └── setup-api-key.sh         # Configure ANTHROPIC_API_KEY
├── configs/
│   └── agents.conf              # Définition des 9 agents
├── claude/                      # Template .claude/ pour tes projets
│   ├── settings.json            # Permissions + hooks
│   ├── board.md, team.md        # Fichiers de coordination
│   ├── workflow.md              # Workflow des agents
│   ├── hooks/                   # Hooks pre/post
│   ├── rules/                   # Style de code, commits, branches
│   └── skills/                  # Définitions des 9 agents
├── terraform/                   # Provisionnement Azure (optionnel)
└── docs/                        # Documentation détaillée
```

## License

MIT
