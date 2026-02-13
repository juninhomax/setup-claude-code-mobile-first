#!/usr/bin/env bash
# =============================================================================
# 04-install-claude-code.sh — Install Node.js LTS + Claude Code CLI
# Usage: bash 04-install-claude-code.sh  (no sudo needed)
# =============================================================================
set -euo pipefail

echo "=========================================="
echo "  CLAUDE CODE INSTALLATION"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.env"
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

# --- Node.js LTS via nvm ---
echo "[1/4] Installing Node.js LTS via nvm..."
if command -v node &>/dev/null && node -v | grep -qE '^v(20|22|24)'; then
  echo "  -> Node.js already installed: $(node -v)"
else
  if [[ ! -d "$HOME/.nvm" ]]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'
  echo "  -> Node.js installed: $(node -v)"
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "  -> npm: $(npm -v)"

# --- Claude Code CLI ---
echo "[2/4] Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code
echo "  -> Claude Code installed: $(claude --version 2>/dev/null || echo 'check PATH')"

# --- API key configuration ---
echo "[3/4] Configuring Anthropic API key..."

ENV_FILE="$HOME/.claude-env"
if [[ ! -f "${ENV_FILE}" ]]; then
  ANTHROPIC_KEY="${ANTHROPIC_API_KEY:-sk-ant-YOUR-KEY-HERE}"
  cat > "${ENV_FILE}" << ENVEOF
# === Claude Code — Environment variables ===
export ANTHROPIC_API_KEY="${ANTHROPIC_KEY}"

# Optional: default model
# export CLAUDE_MODEL="claude-sonnet-4-20250514"
ENVEOF
  chmod 600 "${ENV_FILE}"
  echo "  -> File ${ENV_FILE} created (chmod 600)."
  if [[ "$ANTHROPIC_KEY" == "sk-ant-YOUR-KEY-HERE" || "$ANTHROPIC_KEY" == "sk-ant-..." ]]; then
    echo "  -> EDIT IT with your API key: nano ${ENV_FILE}"
  fi
else
  echo "  -> File ${ENV_FILE} already exists."
fi

# Add sourcing to .bashrc if absent
if ! grep -q 'claude-env' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" << 'RCEOF'

# --- Claude Code env ---
if [[ -f "$HOME/.claude-env" ]]; then
  source "$HOME/.claude-env"
fi
RCEOF
  echo "  -> Sourcing added to .bashrc"
fi

# --- Verification ---
echo "[4/4] Verification..."
echo ""

source "${ENV_FILE}" 2>/dev/null || true

if command -v claude &>/dev/null; then
  echo "  Claude Code CLI found: $(which claude)"
  echo "  Version: $(claude --version 2>/dev/null || echo 'N/A')"
else
  echo "  WARNING: 'claude' not in PATH."
  echo "  Try: source ~/.bashrc && claude --version"
fi

echo ""
echo "=========================================="
echo "  INSTALLATION COMPLETE"
echo ""
echo "  NEXT STEPS:"
echo "  1. Edit your API key:"
echo "     nano ~/.claude-env"
echo ""
echo "  2. Reload shell:"
echo "     source ~/.bashrc"
echo ""
echo "  3. Test:"
echo "     claude --version"
echo "     claude 'say hello'"
echo "=========================================="
