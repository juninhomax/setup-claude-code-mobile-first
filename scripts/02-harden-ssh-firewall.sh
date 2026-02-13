#!/usr/bin/env bash
# =============================================================================
# 02-harden-ssh-firewall.sh — SSH hardening + UFW + fail2ban
# Usage: sudo bash 02-harden-ssh-firewall.sh [--option-a | --option-b]
#   --option-a : Public IP exposed (ports 22, 443, 8080)
#   --option-b : Tailscale only (no public ports) [default]
# =============================================================================
set -euo pipefail

echo "=========================================="
echo "  SSH + FIREWALL HARDENING"
echo "=========================================="

# --- Parse arguments ---
OPTION="${1:---option-b}"
WORK_USER="${WORK_USER:-$(logname 2>/dev/null || echo "$SUDO_USER")}"

echo "Mode: ${OPTION}"

# --- Backup sshd_config ---
echo "[1/4] Hardening SSH..."
cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%s)"

# Apply security settings via drop-in file
cat > /etc/ssh/sshd_config.d/90-hardening.conf << 'SSHEOF'
# --- SSH hardening for Claude Code multi-agents ---
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 60
ClientAliveCountMax 120
X11Forwarding no
AllowAgentForwarding yes
AllowTcpForwarding yes
LoginGraceTime 30
SSHEOF

echo "AllowUsers ${WORK_USER}" > /etc/ssh/sshd_config.d/91-allowusers.conf

sshd -t && echo "  -> SSH config valid." || { echo "ERROR: invalid SSH config!"; exit 1; }
systemctl reload sshd
echo "  -> SSH hardened and reloaded."

# --- UFW ---
echo "[2/4] Configuring UFW..."
ufw --force reset

if [[ "${OPTION}" == "--option-a" ]]; then
  echo "  -> Mode A: ports 22 + 443 + 8080 open"
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp comment 'SSH'
  ufw allow 443/tcp comment 'HTTPS web terminal'
  ufw allow 8080/tcp comment 'code-server'
  ufw limit 22/tcp comment 'SSH rate limit'

elif [[ "${OPTION}" == "--option-b" ]]; then
  echo "  -> Mode B: no public ports, Tailscale only"
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow in on tailscale0 comment 'Tailscale'
  ufw allow in on tailscale0 to any port 22 proto tcp comment 'SSH via Tailscale'
  ufw allow in on tailscale0 to any port 443 proto tcp comment 'HTTPS via Tailscale'
  ufw allow in on tailscale0 to any port 8080 proto tcp comment 'code-server via Tailscale'
fi

ufw --force enable
ufw status verbose
echo "  -> UFW enabled."

# --- fail2ban ---
echo "[3/4] Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << 'F2BEOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
F2BEOF

systemctl enable fail2ban
systemctl restart fail2ban
echo "  -> fail2ban configured and active."

# --- Summary ---
echo "[4/4] Summary..."
echo ""
echo "=========================================="
echo "  HARDENING COMPLETE"
echo "  SSH: key-only, root disabled"
echo "  UFW: $(ufw status | head -1)"
echo "  fail2ban: $(systemctl is-active fail2ban)"
echo "=========================================="
