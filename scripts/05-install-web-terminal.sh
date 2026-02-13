#!/usr/bin/env bash
# =============================================================================
# 05-install-web-terminal.sh — Web terminal (ttyd) + Caddy HTTPS
# Usage: sudo bash 05-install-web-terminal.sh [--domain <domain>]
#
# Without domain: HTTPS self-signed (Caddy internal TLS)
# With domain: HTTPS Let's Encrypt via Caddy
# =============================================================================
set -euo pipefail

echo "=========================================="
echo "  WEB TERMINAL (ttyd + Caddy)"
echo "=========================================="

# --- Load config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.env"
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

# --- Arguments ---
DOMAIN="${DOMAIN:-}"
while [[ $# -gt 0 ]]; do
  case $1 in
    --domain) DOMAIN="$2"; shift 2 ;;
    *) shift ;;
  esac
done

WORK_USER="${WORK_USER:-$(logname 2>/dev/null || echo "$SUDO_USER")}"
WEB_PASSWORD="${WEB_PASSWORD:-change-me-strong-password}"
TTYD_PORT="${TTYD_PORT:-7681}"

# --- Install ttyd ---
echo "[1/5] Installing ttyd..."
if command -v ttyd &>/dev/null; then
  echo "  -> ttyd already installed: $(ttyd --version 2>&1 | head -1)"
else
  TTYD_VERSION="1.7.7"
  ARCH=$(dpkg --print-architecture)
  case "${ARCH}" in
    amd64) TTYD_ARCH="x86_64" ;;
    arm64) TTYD_ARCH="aarch64" ;;
    *) echo "Unsupported architecture: ${ARCH}"; exit 1 ;;
  esac
  curl -fsSL -o /usr/local/bin/ttyd \
    "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${TTYD_ARCH}"
  chmod +x /usr/local/bin/ttyd
  echo "  -> ttyd ${TTYD_VERSION} installed."
fi

# --- systemd service for ttyd ---
echo "[2/5] Configuring ttyd service..."
cat > /etc/systemd/system/ttyd.service << TTYDEOF
[Unit]
Description=ttyd - Web terminal for Claude Code
After=network.target

[Service]
Type=simple
User=${WORK_USER}
Group=${WORK_USER}
# Bind ONLY on localhost (Caddy does the reverse proxy)
ExecStart=/usr/local/bin/ttyd \\
  --port ${TTYD_PORT} \\
  --interface 127.0.0.1 \\
  --credential user:${WEB_PASSWORD} \\
  --max-clients 5 \\
  --ping-interval 30 \\
  --writable \\
  tmux new-session -A -s web
Restart=always
RestartSec=3
Environment="HOME=/home/${WORK_USER}"
WorkingDirectory=/home/${WORK_USER}/workspace

[Install]
WantedBy=multi-user.target
TTYDEOF

# --- Install Caddy ---
echo "[3/5] Installing Caddy..."
if command -v caddy &>/dev/null; then
  echo "  -> Caddy already installed: $(caddy version 2>&1 | head -1)"
else
  apt-get install -y -qq debian-keyring debian-archive-keyring apt-transport-https
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
    gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | \
    tee /etc/apt/sources.list.d/caddy-stable.list
  apt-get update -qq
  apt-get install -y -qq caddy
  echo "  -> Caddy installed."
fi

# --- Caddyfile ---
echo "[4/5] Configuring Caddy..."

# Use template if available, otherwise generate
CADDYFILE_TEMPLATE="${SCRIPT_DIR}/../configs/Caddyfile.template"

if [[ -n "${DOMAIN}" ]]; then
  cat > /etc/caddy/Caddyfile << CADDYEOF
# === Claude Code Mobile-First — Caddyfile ===

# Web terminal
${DOMAIN} {
    reverse_proxy 127.0.0.1:${TTYD_PORT}
    encode gzip

    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        Referrer-Policy no-referrer
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
    }

    log {
        output file /var/log/caddy/access.log
        format json
    }
}

# code-server (if installed)
code.${DOMAIN} {
    reverse_proxy 127.0.0.1:8443
    encode gzip
}
CADDYEOF
  echo "  -> Caddy configured for ${DOMAIN} (Let's Encrypt auto)."

else
  cat > /etc/caddy/Caddyfile << 'CADDYEOF'
# === Claude Code Mobile-First — Caddyfile (no domain) ===

# Web terminal on port 443 with self-signed TLS
:443 {
    tls internal
    reverse_proxy 127.0.0.1:7681
    encode gzip

    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        Referrer-Policy no-referrer
    }

    log {
        output file /var/log/caddy/access.log
        format json
    }
}

# code-server on port 8080
:8080 {
    tls internal
    reverse_proxy 127.0.0.1:8443
    encode gzip
}
CADDYEOF
  echo "  -> Caddy configured with self-signed TLS (ports 443 + 8080)."
  echo "  -> Access: https://<IP-or-Tailscale>/"
fi

mkdir -p /var/log/caddy

# --- Enable services ---
echo "[5/5] Enabling services..."
systemctl daemon-reload
systemctl enable --now ttyd
systemctl enable --now caddy

sleep 2
echo ""
echo "  ttyd:  $(systemctl is-active ttyd)"
echo "  caddy: $(systemctl is-active caddy)"

echo ""
echo "=========================================="
echo "  WEB TERMINAL INSTALLED"
echo ""
if [[ -n "${DOMAIN}" ]]; then
  echo "  Access: https://${DOMAIN}/"
else
  echo "  Access: https://<IP-or-Tailscale>/"
  echo "  (accept the self-signed certificate)"
fi
echo ""
echo "  Auth: user / <your WEB_PASSWORD>"
echo "=========================================="
