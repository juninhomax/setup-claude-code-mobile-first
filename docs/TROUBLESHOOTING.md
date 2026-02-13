# Troubleshooting

## Authentication — Skip OAuth completely

Claude Code CLI normally asks you to authenticate via OAuth (browser flow).
This is **very difficult on mobile** (copy-paste issues, `#` in URLs, etc.).

**The solution: set `ANTHROPIC_API_KEY` before running `claude`.**
When this variable is set, Claude Code skips OAuth entirely.

### Quick fix (if you're stuck on the OAuth screen)

```bash
# Press Ctrl+C to cancel the OAuth prompt, then:
export ANTHROPIC_API_KEY="sk-ant-api03-YOUR-KEY-HERE"

# Test it — no OAuth, it just works:
claude "say hello"

# Save it permanently:
echo 'export ANTHROPIC_API_KEY="sk-ant-api03-YOUR-KEY-HERE"' > ~/.claude-env
chmod 600 ~/.claude-env
source ~/.bashrc
```

### Get an API key

1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Sign in (or create an account)
3. Go to **API Keys** > **Create Key**
4. Copy the key (starts with `sk-ant-api03-...`)
5. Add credit ($5 minimum) under **Billing**

### Use the helper script

```bash
# Interactive setup — paste your key and you're done:
bash scripts/setup-api-key.sh
```

### Verify it works

```bash
# Should print your key (masked):
echo $ANTHROPIC_API_KEY | cut -c1-15

# Should work without any OAuth prompt:
claude "say hello"
```

## Setup issues

### `claude: command not found`
```bash
# Reload shell
source ~/.bashrc

# Or load nvm manually
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Verify
which claude
claude --version
```

### `ANTHROPIC_API_KEY not set`
```bash
# Edit your key
nano ~/.claude-env

# Make sure it's sourced
source ~/.claude-env
echo $ANTHROPIC_API_KEY
```

### `permission denied` on scripts
```bash
chmod +x scripts/*.sh
```

### Swap not active
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## tmux issues

### Session already exists
```bash
# List sessions
tmux list-sessions

# Attach to existing
tmux attach -t claude-agents

# Kill and restart
bash scripts/07-launch-agents.sh --kill
bash scripts/07-launch-agents.sh --project ~/workspace/my-project
```

### Agents not starting
```bash
# Check if claude is in PATH within tmux
tmux send-keys -t claude-agents:1 "which claude" Enter

# If not, add to ~/.bashrc:
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ~/.bashrc
```

### tmux prefix not working
```bash
# Verify .tmux.conf is loaded
tmux show -g prefix
# Should show: prefix C-a

# Reload config
tmux source-file ~/.tmux.conf
```

## Web terminal issues

### ttyd not responding
```bash
# Check service
sudo systemctl status ttyd
sudo journalctl -u ttyd -f

# Restart
sudo systemctl restart ttyd
```

### Caddy not responding
```bash
# Check service
sudo systemctl status caddy
sudo journalctl -u caddy -f

# Validate config
caddy validate --config /etc/caddy/Caddyfile

# Restart
sudo systemctl restart caddy
```

### Self-signed certificate warning
This is expected. In Safari:
1. Tap "Show Details"
2. Tap "Visit Website"
3. Confirm in the dialog

For a proper certificate, set up a domain and update the Caddyfile.

### Port blocked by firewall
```bash
# Check UFW status
sudo ufw status verbose

# Add a port
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
```

## code-server issues

### Can't access on port 8080
```bash
# Check if code-server is running
sudo systemctl status code-server@$(whoami)

# Check if Caddy is proxying port 8080
grep -A5 ':8080' /etc/caddy/Caddyfile
```

### Wrong password
```bash
# Check code-server config
cat ~/.config/code-server/config.yaml

# Update password and restart
nano ~/.config/code-server/config.yaml
sudo systemctl restart code-server@$(whoami)
```

## Tailscale issues

### Not connected
```bash
# Check status
tailscale status

# Reconnect
sudo tailscale up --ssh

# If expired, re-authenticate
sudo tailscale up --ssh --reset
```

### Can't access services via Tailscale
```bash
# Check Tailscale IP
tailscale ip -4

# Verify UFW allows tailscale0
sudo ufw status verbose | grep tailscale
```

## Azure / Terraform issues

### Cloud-init not finished
```bash
# Check progress
ssh azureuser@<IP> 'tail -f /var/log/cloud-init-output.log'

# Check completion
ssh azureuser@<IP> 'test -f ~/.cloud-init-complete && echo DONE || echo IN PROGRESS'
```

### Terraform apply fails
```bash
# Ensure you're logged in
az login
az account show

# Check subscription
az account set --subscription "YOUR-SUBSCRIPTION-ID"

# Re-initialize
terraform init -upgrade
terraform plan
```

## Validation

Run the validation script to check everything:
```bash
bash scripts/08-validate.sh
```

This checks: system packages, security, networking, Claude Code, tmux, and optional services.
