# Procedure complete : Claude Code Multi-Agents sur Mobile

> Setup d'un workspace multi-agents accessible depuis ton iPhone sur un serveur Ubuntu existant.

---

## Pre-requis

| Element | Detail |
|---------|--------|
| **Serveur Ubuntu 22.04+** | Avec acces SSH (VPS, VM, machine locale...) |
| **Cle API Anthropic** | `sk-ant-api03-...` depuis [console.anthropic.com](https://console.anthropic.com/settings/keys) |
| **iPhone/iPad** | Safari avec acces internet |

---

## Etape 1 — Cloner le repo et configurer

Sur le serveur :

```bash
git clone https://github.com/juninhomax/setup-claude-code-mobile-first.git
cd setup-claude-code-mobile-first
```

Copier et remplir le fichier de config :

```bash
cp config.env.example config.env
nano config.env
```

Remplir les valeurs **obligatoires** :

```bash
# Cle API Anthropic
ANTHROPIC_API_KEY="sk-ant-api03-TA-CLE-ICI"

# Mot de passe pour le terminal web et VS Code (choisis un vrai mdp !)
WEB_PASSWORD="MonSuperMotDePasse123!"
```

---

## Etape 2 — Lancer le setup

```bash
sudo bash scripts/setup.sh
```

Le script installe tout automatiquement :
- Packages systeme, swap, securite (SSH, fail2ban, UFW)
- Node.js + Claude Code CLI
- Terminal web (ttyd) + proxy HTTPS (Caddy)
- VS Code web (code-server)

Options utiles :

```bash
# Sauter une etape (ex: etape 3)
sudo bash scripts/setup.sh --skip 3

# Reprendre a partir d'une etape
sudo bash scripts/setup.sh --from 4

# Lancer seulement certaines etapes
sudo bash scripts/setup.sh --only 1 2
```

---

## Etape 3 — Configurer la cle API

```bash
bash scripts/setup-api-key.sh sk-ant-api03-TA-CLE-ICI
```

Tester que ca marche :

```bash
source ~/.bashrc
claude "say hello"
```

> La premiere fois, Claude affiche un lien a ouvrir dans le navigateur pour activer la session. C'est normal — suis le lien, apres ca marche directement.

---

## Etape 4 — Acceder depuis l'iPhone

### Terminal Web (ttyd)

1. Ouvrir Safari sur ton iPhone
2. Aller a `https://<IP-DU-SERVEUR>/`
3. Safari affiche un avertissement de certificat (auto-signe) :
   - Taper **"Afficher les details"** > **"Consulter le site web"**
4. Se connecter :
   - Utilisateur : `user`
   - Mot de passe : celui defini dans `WEB_PASSWORD`
5. Tu es dans un terminal sur le serveur !

### VS Code Web (code-server)

1. Ouvrir Safari
2. Aller a `https://<IP-DU-SERVEUR>:8080/`
3. Accepter le certificat (meme manip)
4. Entrer le `WEB_PASSWORD`
5. Tu as VS Code complet dans le navigateur !

> **Astuce iPhone** : "Ajouter a l'ecran d'accueil" pour un acces plein ecran comme une app native.

---

## Etape 5 — Lancer les agents multi-Claude

Depuis le terminal web (ou SSH) :

```bash
# Cloner ou creer ton projet
cd ~/workspace
git clone https://github.com/ton-user/ton-projet.git
cd ton-projet

# Lancer les 9 agents
bash ~/setup-claude-code-mobile-first/scripts/07-launch-agents.sh \
  --project ~/workspace/ton-projet
```

Ca lance une session **tmux** avec 9 agents specialises + un moniteur :

| Tab | Agent | Modele | Role |
|-----|-------|--------|------|
| 1 | orchestrateur | Opus | Cerveau central, planifie et coordonne |
| 2 | backend-dev | Sonnet | API REST, Express.js, logique metier |
| 3 | frontend-dev | Sonnet | UI/UX, responsive, mobile-first |
| 4 | admin-sys | Sonnet | Infra, reseau, securite systeme |
| 5 | devops | Sonnet | CI/CD, Docker, Terraform, monitoring |
| 6 | testeur | Haiku | Tests unitaires, integration, E2E |
| 7 | reviewer | Sonnet | Revue code + securite OWASP |
| 8 | stabilizer | Sonnet | Verification build, tests, deploy |
| 9 | manager | Opus | Suivi projet, priorisation, rapports |
| 10 | monitor | - | `watch` sur git status + board |

### Lancer seulement certains agents

```bash
# Juste l'orchestrateur et le backend
bash ~/setup-claude-code-mobile-first/scripts/07-launch-agents.sh \
  --project ~/workspace/ton-projet \
  --agents orchestrateur backend-dev testeur

# Voir la liste des agents disponibles
bash ~/setup-claude-code-mobile-first/scripts/07-launch-agents.sh --list

# Arreter tous les agents
bash ~/setup-claude-code-mobile-first/scripts/07-launch-agents.sh --kill
```

---

## Etape 6 — Naviguer dans tmux depuis l'iPhone

Le prefixe tmux est **Ctrl+A** (plus facile que Ctrl+B sur mobile).

| Action | Raccourci |
|--------|-----------|
| Aller a l'agent N | `Ctrl+A` puis `1` a `9` |
| Agent suivant | `Ctrl+A` puis `Tab` |
| Agent precedent | `Ctrl+A` puis `Shift+Tab` |
| Vue arbre (tous les agents) | `Ctrl+A` puis `w` |
| Scroller vers le haut | `Ctrl+A` puis `[` puis fleches |
| Se detacher (agents continuent) | `Ctrl+A` puis `d` |
| Se re-attacher | `tmux attach -t claude-agents` |

> Les agents **continuent de tourner** meme si tu fermes Safari. Il suffit de revenir et taper `tmux attach -t claude-agents`.

---

## Comment les agents collaborent

Les agents se coordonnent via le fichier `.claude/board.md` dans ton projet :

```markdown
# Board de coordination multi-agents

## Projet en cours
**US**: Implementer l'authentification JWT
**Branche**: feature/auth-jwt
**Statut**: en cours

## Taches
| # | Agent | Tache | Statut | Notes |
|---|-------|-------|--------|-------|
| 1 | backend-dev | API /login + /register | done | |
| 2 | frontend-dev | Formulaire login | in-progress | |
| 3 | testeur | Tests auth | pending | attend backend |

## Messages inter-agents
[orchestrateur -> backend-dev] API auth terminee, passe au middleware JWT
[backend-dev -> testeur] Endpoints prets, tu peux ecrire les tests
```

L'**orchestrateur** distribue les taches, chaque agent met a jour son statut, le **manager** suit l'avancement.

---

## Resume des URLs d'acces

| Service | URL | Port |
|---------|-----|------|
| Terminal web | `https://<IP>/` | 443 |
| VS Code web | `https://<IP>:8080/` | 8080 |
| SSH direct | `ssh user@<IP>` | 22 |

---

## Depannage rapide

| Probleme | Solution |
|----------|----------|
| Safari dit "Non securise" | Normal (certif auto-signe). Accepter le certificat |
| Connexion coupee sur iPhone | `tmux attach -t claude-agents` pour reprendre |
| Agent ne demarre pas | Verifier `~/.claude-env` et relancer le script |
| Trop cher en API | Changer les agents Opus en Sonnet dans `configs/agents.conf` |
| Ajouter un agent custom | Ajouter une ligne dans `configs/agents.conf` et relancer |
