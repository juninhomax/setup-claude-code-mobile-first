#!/usr/bin/env bash
# =============================================================================
# 07-launch-agents.sh — Launch tmux multi-agent Claude Code workspace
#
# Each tab = a specialized agent with its model and role.
# All agents collaborate on the same project via the shared board.
#
# Usage:
#   bash scripts/07-launch-agents.sh --project /path/to/project
#   bash scripts/07-launch-agents.sh --project /path --agents orchestrateur backend-dev
#   bash scripts/07-launch-agents.sh --list
#   bash scripts/07-launch-agents.sh --kill
# =============================================================================
set -euo pipefail

# --- Load config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${REPO_DIR}/config.env"
AGENTS_CONF="${REPO_DIR}/configs/agents.conf"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

if [[ -f "$AGENTS_CONF" ]]; then
  # shellcheck source=/dev/null
  source "$AGENTS_CONF"
fi

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Configuration ---
SESSION="claude-agents"
PROJECT_DIR="${PROJECT_DIR:-$HOME/workspace}"

# --- Fallback agent definitions (if agents.conf not loaded) ---
if [[ -z "${AGENTS_DEF+x}" ]]; then
  AGENTS_DEF=(
    "orchestrateur|opus|Central brain — plans, coordinates, reviews"
    "backend-dev|sonnet|REST API, Express.js, WebSocket, business logic"
    "frontend-dev|sonnet|UI/UX, SPA vanilla JS, responsive mobile-first"
    "admin-sys|sonnet|Infrastructure, networking, system security"
    "devops|sonnet|CI/CD, Docker, cloud deploy, Terraform, monitoring"
    "testeur|haiku|Unit tests, integration, E2E, quality"
    "reviewer|sonnet|Code review: quality + security OWASP"
    "stabilizer|sonnet|Build, tests, deploy verification"
    "manager|opus|Project tracking, prioritization, reports"
  )
fi

# --- System prompts per agent ---
get_system_prompt() {
  local agent="$1"
  local base="You are a specialized agent for this project.
COORDINATION: Read .claude/board.md at the start of each session to see your assigned tasks. After each significant action, update .claude/board.md with your progress.
PROJECT: Read CLAUDE.md for the full project context.
BRANCH: Always work on the active branch (check with git branch --show-current)."

  case "$agent" in
    orchestrateur)
      echo "${base}
ROLE: You are the ORCHESTRATOR (claude-opus-4-6), the central brain of the team.
MISSION: You decompose projects into tasks, plan execution, coordinate agents, and review outputs.
RULES:
- You DO NOT modify code directly
- You write plans and assignments in .claude/board.md
- You read other agents' outputs and give feedback
- You validate task completion before moving to the next
- Use format: [orchestrateur -> agent] Message"
      ;;
    backend-dev)
      echo "${base}
ROLE: You are the BACKEND DEV (claude-sonnet), Express.js and Node.js specialist.
MISSION: You implement REST APIs, business logic, WebSocket, backend security.
RULES:
- Read existing code before modifying (Read before Edit)
- Atomic commits: type(scope): description
- Verify server starts after each change
- Broadcast state changes via WebSocket
- Validate all inputs, no injection"
      ;;
    frontend-dev)
      echo "${base}
ROLE: You are the FRONTEND DEV (claude-sonnet), UI/UX specialist.
MISSION: You implement the SPA interface, mobile-first, responsive, accessible.
RULES:
- No JS framework (vanilla only)
- Mobile-first: everything must be responsive
- WebSocket client for real-time updates
- Modular and reusable components
- Accessibility (ARIA, contrast, keyboard navigation)"
      ;;
    admin-sys)
      echo "${base}
ROLE: You are the ADMIN SYS/NETWORK (claude-sonnet), infrastructure specialist.
MISSION: You configure infrastructure, system security, networking, servers.
RULES:
- Security: SSH hardening, firewall, HTTPS
- System monitoring and alerts
- Document all configuration changes"
      ;;
    devops)
      echo "${base}
ROLE: You are the DEVOPS (claude-sonnet), CI/CD and deployment specialist.
MISSION: You manage Docker, cloud services, Terraform, CI/CD pipelines, monitoring.
RULES:
- Unique image tags (not just latest)
- Terraform for infra
- Health checks on all services
- Always verify after deploy"
      ;;
    testeur)
      echo "${base}
ROLE: You are the TESTER (claude-haiku), quality specialist.
MISSION: You write and execute unit, integration, and E2E tests. You report results.
RULES:
- Cover nominal AND error cases
- Test API endpoints with real requests
- Verify responses (status, body, headers)
- Clear report: X passed, Y failed, Z to fix"
      ;;
    reviewer)
      echo "${base}
ROLE: You are the REVIEWER (claude-sonnet), quality and security specialist.
MISSION: You do code review for quality + OWASP security. You analyze without modifying.
RULES:
- You DO NOT modify files
- Check: injection, XSS, auth bypass, CSRF, hardcoded secrets
- Check: error handling, input validation, rate limiting
- Report format: [OK] valid / [WARN] attention / [FAIL] must fix"
      ;;
    stabilizer)
      echo "${base}
ROLE: You are the STABILIZER, stability guardian.
MISSION: You verify everything works: server start, build, tests, deploy.
RULES:
- Check 1: server starts without error
- Check 2: API endpoints respond
- Check 3: Build passes
- Check 4: No regressions
- If a check fails: fix and rerun ALL checks"
      ;;
    manager)
      echo "${base}
ROLE: You are the MANAGER (claude-opus-4-6), project lead.
MISSION: You track progress, prioritize, resolve conflicts, write reports.
RULES:
- You DO NOT modify code
- Read .claude/board.md and GitHub issues for tracking
- Detect blockers and propose solutions
- Report format: summary, progress %, blockers, next steps"
      ;;
  esac
}

# --- Utility functions ---
get_agent_model() {
  local agent="$1"
  for def in "${AGENTS_DEF[@]}"; do
    IFS='|' read -r name model desc <<< "$def"
    if [[ "$name" == "$agent" ]]; then
      echo "$model"
      return
    fi
  done
  echo "sonnet"
}

get_agent_desc() {
  local agent="$1"
  for def in "${AGENTS_DEF[@]}"; do
    IFS='|' read -r name model desc <<< "$def"
    if [[ "$name" == "$agent" ]]; then
      echo "$desc"
      return
    fi
  done
}

list_agents() {
  echo -e "${BOLD}Available agents:${NC}"
  echo ""
  for def in "${AGENTS_DEF[@]}"; do
    IFS='|' read -r name model desc <<< "$def"
    printf "  ${CYAN}%-15s${NC} ${YELLOW}%-7s${NC} %s\n" "$name" "($model)" "$desc"
  done
}

init_board() {
  local board_file="${PROJECT_DIR}/.claude/board.md"
  if [[ ! -f "$board_file" ]]; then
    mkdir -p "$(dirname "$board_file")"
    cat > "$board_file" << 'BOARDEOF'
# Board de coordination multi-agents

> Shared board between all Claude Code agents.
> Each agent reads and updates this board to coordinate work.

## Current project

**US** : (to be defined by orchestrator)
**Branch** : (to be defined)
**Status** : idle

## Tasks

| # | Agent | Task | Status | Notes |
|---|-------|------|--------|-------|
| - | - | No tasks assigned | - | - |

## Inter-agent messages

<!-- Format: [sender -> recipient] Message -->

## Journal

<!-- Format: [HH:MM] [agent] Action performed -->

BOARDEOF
    echo -e "  ${GREEN}+${NC} Coordination board created: .claude/board.md"
  else
    echo -e "  ${YELLOW}->${NC} Existing board preserved: .claude/board.md"
  fi
}

# --- Parse arguments ---
SELECTED_AGENTS=()
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --project)
      PROJECT_DIR="$2"
      shift 2
      ;;
    --list)
      list_agents
      exit 0
      ;;
    --kill)
      if tmux has-session -t "${SESSION}" 2>/dev/null; then
        tmux kill-session -t "${SESSION}"
        echo -e "${GREEN}Session '${SESSION}' closed.${NC}"
      else
        echo -e "${YELLOW}No active session '${SESSION}'.${NC}"
      fi
      exit 0
      ;;
    --agents)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        SELECTED_AGENTS+=("$1")
        shift
      done
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# If no agents specified via --agents, use all
if [[ ${#SELECTED_AGENTS[@]} -eq 0 ]]; then
  if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
    SELECTED_AGENTS=("${POSITIONAL_ARGS[@]}")
  else
    for def in "${AGENTS_DEF[@]}"; do
      IFS='|' read -r name model desc <<< "$def"
      SELECTED_AGENTS+=("$name")
    done
  fi
fi

# --- Validate agents ---
for agent in "${SELECTED_AGENTS[@]}"; do
  found=false
  for def in "${AGENTS_DEF[@]}"; do
    IFS='|' read -r name model desc <<< "$def"
    if [[ "$name" == "$agent" ]]; then
      found=true
      break
    fi
  done
  if [[ "$found" == "false" ]]; then
    echo -e "${RED}Unknown agent: ${agent}${NC}"
    echo "Valid agents: $(for d in "${AGENTS_DEF[@]}"; do IFS='|' read -r n m d <<< "$d"; echo -n "$n "; done)"
    exit 1
  fi
done

# --- Pre-flight checks ---
preflight_ok=true

# Check Node.js / npm
if ! command -v node &>/dev/null; then
  echo -e "${RED}[MISSING] Node.js is not installed.${NC}"
  echo -e "  Run: ${BOLD}bash scripts/04-install-claude-code.sh${NC}"
  preflight_ok=false
fi

if ! command -v npm &>/dev/null; then
  echo -e "${RED}[MISSING] npm is not installed.${NC}"
  echo -e "  Run: ${BOLD}bash scripts/04-install-claude-code.sh${NC}"
  preflight_ok=false
fi

# Check Claude Code CLI
if ! command -v claude &>/dev/null; then
  echo -e "${RED}[MISSING] Claude Code CLI is not installed.${NC}"
  echo -e "  Run: ${BOLD}npm install -g @anthropic-ai/claude-code${NC}"
  preflight_ok=false
fi

# Check tmux
if ! command -v tmux &>/dev/null; then
  echo -e "${RED}[MISSING] tmux is not installed.${NC}"
  echo -e "  Run: ${BOLD}sudo apt install tmux${NC}"
  preflight_ok=false
fi

if [[ "$preflight_ok" == "false" ]]; then
  echo ""
  echo -e "${RED}Pre-flight checks failed. Install missing dependencies first.${NC}"
  exit 1
fi

# --- Install tmux config (mouse support, mobile optimizations) ---
TMUX_CONF_SRC="${REPO_DIR}/configs/.tmux.conf"
TMUX_CONF_DST="$HOME/.tmux.conf"

if [[ -f "$TMUX_CONF_SRC" ]]; then
  if [[ ! -f "$TMUX_CONF_DST" ]] || ! diff -q "$TMUX_CONF_SRC" "$TMUX_CONF_DST" &>/dev/null; then
    cp "$TMUX_CONF_SRC" "$TMUX_CONF_DST"
    echo -e "  ${GREEN}+${NC} tmux config installed: ${TMUX_CONF_DST}"
    # Reload config in any existing tmux server
    tmux source-file "$TMUX_CONF_DST" 2>/dev/null || true
  fi
fi

# --- Launch ---
echo -e "${BOLD}=========================================="
echo -e "  CLAUDE AGENTS — Multi-Agent Workspace"
echo -e "==========================================${NC}"
echo ""
echo -e "  Project : ${CYAN}${PROJECT_DIR}${NC}"
echo -e "  Agents  : ${GREEN}${#SELECTED_AGENTS[@]}${NC} (${SELECTED_AGENTS[*]})"
echo ""

# Check for existing session
if tmux has-session -t "${SESSION}" 2>/dev/null; then
  echo -e "${YELLOW}Session '${SESSION}' already active.${NC}"
  echo -e "  -> ${BOLD}tmux attach -t ${SESSION}${NC} to rejoin"
  echo -e "  -> ${BOLD}$0 --kill${NC} to close and relaunch"
  exit 0
fi

# Verify project directory exists
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo -e "${RED}Project directory does not exist: ${PROJECT_DIR}${NC}"
  echo "  Create it or pass --project /path/to/project"
  exit 1
fi

# Initialize coordination board
init_board

# Directory for launch scripts
PROMPT_DIR="/tmp/claude-agents-prompts"
mkdir -p "${PROMPT_DIR}"

# Generate a launch script per agent
for idx in "${!SELECTED_AGENTS[@]}"; do
  agent="${SELECTED_AGENTS[$idx]}"
  model=$(get_agent_model "$agent")
  prompt=$(get_system_prompt "$agent")

  cat > "${PROMPT_DIR}/launch-${agent}.sh" <<LAUNCHEOF
#!/usr/bin/env bash
PROMPT=\$(cat <<'PROMPTEOF'
${prompt}
PROMPTEOF
)
exec claude --model ${model} --append-system-prompt "\${PROMPT}"
LAUNCHEOF
  chmod +x "${PROMPT_DIR}/launch-${agent}.sh"
done

# Create tmux session with first agent
first_agent="${SELECTED_AGENTS[0]}"
first_model=$(get_agent_model "$first_agent")

echo -e "  ${GREEN}[1/${#SELECTED_AGENTS[@]}]${NC} ${BOLD}${first_agent}${NC} (${first_model})"

tmux new-session -d -s "${SESSION}" -n "${first_agent}" -c "${PROJECT_DIR}"
tmux send-keys -t "${SESSION}:${first_agent}" "bash ${PROMPT_DIR}/launch-${first_agent}.sh" Enter

# Create windows for other agents
for i in $(seq 1 $(( ${#SELECTED_AGENTS[@]} - 1 ))); do
  agent="${SELECTED_AGENTS[$i]}"
  model=$(get_agent_model "$agent")

  echo -e "  ${GREEN}[$((i+1))/${#SELECTED_AGENTS[@]}]${NC} ${BOLD}${agent}${NC} (${model})"

  tmux new-window -t "${SESSION}" -n "${agent}" -c "${PROJECT_DIR}"
  sleep 0.3
  tmux send-keys -t "${SESSION}:${agent}" "bash ${PROMPT_DIR}/launch-${agent}.sh" Enter
done

# Monitor window
tmux new-window -t "${SESSION}" -n "monitor" -c "${PROJECT_DIR}"
tmux send-keys -t "${SESSION}:monitor" \
  "watch -n 5 'echo \"=== GIT STATUS ===\"; git status -s; echo \"\"; echo \"=== BOARD ===\"; head -30 .claude/board.md 2>/dev/null; echo \"\"; echo \"=== LAST COMMITS ===\"; git log --oneline -3'" Enter

# Go back to first agent
tmux select-window -t "${SESSION}:${first_agent}"

# Apply tmux config to session (mouse, prefix, mobile optimizations)
if [[ -f "$HOME/.tmux.conf" ]]; then
  tmux source-file "$HOME/.tmux.conf"
fi

# Ensure mouse is always enabled (critical for mobile)
tmux set-option -g mouse on

# Custom status bar
tmux set-option -t "${SESSION}" status-style "bg=colour235,fg=colour136"
tmux set-option -t "${SESSION}" status-left "#[fg=colour235,bg=colour136,bold] AGENTS #[fg=colour136,bg=colour235] "
tmux set-option -t "${SESSION}" status-left-length 20
tmux set-option -t "${SESSION}" window-status-format "#[fg=colour244] #I:#W "
tmux set-option -t "${SESSION}" window-status-current-format "#[fg=colour235,bg=colour33,bold] #I:#W "
tmux set-option -t "${SESSION}" status-right "#[fg=colour244]#{session_windows} tabs #[fg=colour136]| %H:%M "

echo ""
echo -e "${BOLD}=========================================="
echo -e "  AGENTS LAUNCHED${NC}"
echo -e ""
echo -e "  ${CYAN}tmux shortcuts:${NC}"
echo -e "    Ctrl+a, 1-9     Go to agent N"
echo -e "    Ctrl+a, n/p      Next/previous agent"
echo -e "    Ctrl+a, w        Agent list (tree view)"
echo -e "    Ctrl+a, d        Detach (agents continue)"
echo -e ""
echo -e "  ${CYAN}Workflow:${NC}"
echo -e "    1. Orchestrator plans in .claude/board.md"
echo -e "    2. Each agent reads its tasks and executes"
echo -e "    3. Monitor (last tab) shows real-time state"
echo -e ""
echo -e "  ${GREEN}-> tmux attach -t ${SESSION}${NC}"
echo -e "==========================================${NC}"

# Attach session
exec tmux attach-session -t "${SESSION}"
