# Procedure complete : Claude Code Multi-Agents sur Mobile

> De zero a un workspace multi-agents accessible depuis ton iPhone en ~10 minutes.

---

## Pre-requis

| Element | Detail |
|---------|--------|
| **Compte Azure** | Avec un abonnement actif |
| **Cle API Anthropic** | `sk-ant-api03-...` depuis [console.anthropic.com](https://console.anthropic.com/settings/keys) |
| **Cle SSH** | `~/.ssh/id_ed25519` (ou en generer une) |
| **Azure CLI** | `az` installe sur ta machine locale |
| **Terraform** | `terraform` installe sur ta machine locale |
| **iPhone/iPad** | Safari avec acces internet |

---

## Etape 1 — Cloner le repo et configurer

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

# Azure (Service Principal)
ARM_CLIENT_ID="ton-client-id"
ARM_TENANT_ID="ton-tenant-id"
ARM_SUBSCRIPTION_ID="ton-subscription-id"
ARM_CLIENT_SECRET="ton-client-secret"
```

---

## Etape 2 — Deployer la VM Azure avec Terraform

```bash
cd terraform
```

Configurer les variables Terraform :

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Remplir au minimum :

```hcl
subscription_id    = "ton-subscription-id"
location           = "westeurope"        # ou "uksouth", "francecentral"...
vm_size            = "Standard_B2s"      # petit et pas cher (~30$/mois)
enable_public_ip   = true
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
```

Deployer :

```bash
# Se connecter a Azure
az login

# Initialiser Terraform
terraform init

# Verifier ce qui va etre cree
terraform plan

# Deployer (confirmer avec "yes")
terraform apply
```

> Terraform cree : Resource Group, VNet, NSG (firewall), IP publique, VM Ubuntu 24.04 avec cloud-init.

Noter l'IP de sortie :

```bash
terraform output vm_public_ip
terraform output -raw web_password
```

---

## Etape 3 — Attendre que cloud-init finisse (~3-5 min)

La VM s'auto-configure au demarrage (Node.js, Claude CLI, ttyd, Caddy...).

Verifier que c'est termine :

```bash
AZURE_IP=$(terraform output -raw vm_public_ip)

# Tester si cloud-init a fini
ssh -i ~/.ssh/id_ed25519 azureuser@$AZURE_IP \
  'test -f ~/.cloud-init-complete && echo "PRET !" || echo "En cours..."'
```

Repeter toutes les 30 secondes jusqu'a voir **PRET !**

---

## Etape 4 — Configurer la cle API sur la VM

```bash
ssh -i ~/.ssh/id_ed25519 azureuser@$AZURE_IP
```

Une fois connecte sur la VM :

```bash
bash scripts/setup-api-key.sh sk-ant-api03-TA-CLE-ICI
```

Tester que ca marche :

```bash
source ~/.bashrc
claude "say hello"
```

> Tu devrais voir Claude repondre. Il affiche un lien a ouvrir dans le navigateur la premiere fois — c'est normal, suis le lien pour activer, apres ca marche directement.

---

## Etape 5 — Acceder depuis l'iPhone

### Terminal Web (ttyd)

1. Ouvrir Safari sur ton iPhone
2. Aller a `https://<IP-DE-LA-VM>/`
3. Safari affiche un avertissement de certificat (auto-signe) :
   - Taper **"Afficher les details"** > **"Consulter le site web"**
4. Se connecter :
   - Utilisateur : `user`
   - Mot de passe : celui defini dans `WEB_PASSWORD`
5. Tu es dans un terminal sur la VM !

### VS Code Web (code-server)

1. Ouvrir Safari
2. Aller a `https://<IP-DE-LA-VM>:8080/`
3. Accepter le certificat (meme manip)
4. Entrer le `WEB_PASSWORD`
5. Tu as VS Code complet dans le navigateur !

> **Astuce iPhone** : "Ajouter a l'ecran d'accueil" pour un acces plein ecran comme une app native.

---

## Etape 6 — Lancer les agents multi-Claude

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

## Etape 7 — Naviguer dans tmux depuis l'iPhone

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
| SSH direct | `ssh -i ~/.ssh/id_ed25519 azureuser@<IP>` | 22 |

---

## Depannage rapide

| Probleme | Solution |
|----------|----------|
| Safari dit "Non securise" | Normal (certif auto-signe). Accepter le certificat |
| Connexion coupee sur iPhone | `tmux attach -t claude-agents` pour reprendre |
| Agent ne demarre pas | Verifier `~/.claude-env` et relancer le script |
| Oublie du mot de passe web | `terraform output -raw web_password` |
| Trop cher en API | Changer les agents Opus en Sonnet dans `configs/agents.conf` |
| Ajouter un agent custom | Ajouter une ligne dans `configs/agents.conf` et relancer |

---

## Detruire l'infra (quand tu as fini)

```bash
cd terraform
terraform destroy
```

> Tout est supprime (VM, IP, disques, reseau). Aucun cout residuel.
