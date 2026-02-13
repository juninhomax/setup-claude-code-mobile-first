#!/usr/bin/env bash
# =============================================================================
# 03-install-tailscale.sh — Install Tailscale VPN
# Usage: sudo bash 03-install-tailscale.sh
# =============================================================================
set -euo pipefail

echo "=========================================="
echo "  TAILSCALE INSTALLATION"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.env"
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

# --- Install ---
echo "[1/3] Installing Tailscale..."
if command -v tailscale &>/dev/null; then
  echo "  -> Tailscale already installed: $(tailscale version)"
else
  curl -fsSL https://tailscale.com/install.sh | sh
  echo "  -> Tailscale installed."
fi

# --- Enable ---
echo "[2/3] Enabling Tailscale..."
systemctl enable --now tailscaled

# --- Auto-connect if auth key provided ---
if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
  echo "[3/3] Connecting with auth key..."
  tailscale up --ssh --authkey "${TAILSCALE_AUTH_KEY}"
  echo "  -> Connected. IP: $(tailscale ip -4 2>/dev/null || echo 'pending')"
else
  echo ""
  echo "=========================================="
  echo "  TAILSCALE INSTALLED"
  echo ""
  echo "  NEXT STEP (manual):"
  echo "  Run this command and follow the link:"
  echo ""
  echo "    sudo tailscale up --ssh"
  echo ""
  echo "  The --ssh flag enables built-in Tailscale SSH"
  echo "  (no need to expose port 22 publicly)"
  echo ""
  echo "  After connecting, verify with:"
  echo "    tailscale status"
  echo "    tailscale ip -4"
  echo "=========================================="
fi

echo ""
echo "[TIP] Enable MagicDNS in the Tailscale console:"
echo "  -> https://login.tailscale.com/admin/dns"
echo "  -> Then you can use: ssh user@hostname"
echo ""
