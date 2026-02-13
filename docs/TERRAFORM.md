# Terraform — Azure VM Provisioning

## Overview

The `terraform/` directory contains infrastructure-as-code to provision an Azure VM pre-configured for the Claude Code multi-agent workspace. This is **optional** — you can use any Ubuntu server.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (`az`)
- An Azure subscription
- An SSH key pair

## Quick start

```bash
cd terraform

# 1. Configure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
# Set: subscription_id, ssh_public_key_path, location, vm_size

# 2. Login to Azure
az login

# 3. Deploy
terraform init
terraform plan    # Review changes
terraform apply   # Create resources
```

## Configuration options

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | `westeurope` | Azure region |
| `vm_size` | `Standard_B2s` | VM size |
| `admin_username` | `azureuser` | SSH user |
| `ssh_public_key_path` | `~/.ssh/id_rsa.pub` | SSH public key |
| `os_disk_size_gb` | `30` | Disk size |
| `enable_public_ip` | `true` | Public IP (false = Tailscale only) |
| `allowed_ssh_cidr` | `0.0.0.0/0` | SSH source restriction |
| `web_password` | _(auto)_ | Password for ttyd/code-server |

## VM sizes guide

| Size | vCPU | RAM | Monthly cost | Agents |
|------|------|-----|-------------|--------|
| Standard_B2s | 2 | 4 GB | ~$30 | 1-2 |
| Standard_B2ms | 2 | 8 GB | ~$45 | 2-3 |
| Standard_B4ms | 4 | 16 GB | ~$60 | 3+ |
| Standard_D4s_v5 | 4 | 16 GB | ~$140 | 9 (full team) |

## What cloud-init does

After the VM is created, cloud-init automatically:
1. Installs packages (git, tmux, jq, etc.)
2. Hardens SSH and enables fail2ban
3. Installs Node.js via nvm
4. Installs Claude Code CLI
5. Installs ttyd web terminal with HTTPS
6. Configures tmux for mobile use

Wait 3-5 minutes for cloud-init to complete:
```bash
ssh azureuser@<IP> 'test -f ~/.cloud-init-complete && echo READY || echo IN PROGRESS'
```

## After deployment

```bash
# 1. Get connection info
terraform output ssh_command
terraform output web_terminal_url
terraform output -raw web_password

# 2. SSH in
ssh -i ~/.ssh/id_ed25519 azureuser@<IP>

# 3. Configure API key
nano ~/.claude-env

# 4. Clone this repo on the VM
git clone https://github.com/juninhomax/setup-claude-code-mobile-first.git

# 5. Copy .claude/ template to your project
cp -r setup-claude-code-mobile-first/claude/ ~/workspace/my-project/.claude/

# 6. Launch agents
bash setup-claude-code-mobile-first/scripts/07-launch-agents.sh \
  --project ~/workspace/my-project
```

## Option A vs Option B

### Option A: Public IP (`enable_public_ip = true`)
- SSH port 22 open (restricted by `allowed_ssh_cidr`)
- HTTPS port 443 open (web terminal)
- Port 8080 open (code-server)
- **Easier** but less secure

### Option B: Tailscale only (`enable_public_ip = false`)
- No public ports
- Access only via Tailscale VPN
- **More secure** but requires Tailscale setup
- After deploy: `sudo tailscale up --ssh`

## Cleanup

```bash
terraform destroy   # Removes all resources
```
