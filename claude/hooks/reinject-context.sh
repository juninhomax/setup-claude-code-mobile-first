#!/bin/bash
# reinject-context.sh -- Reinject critical context after compaction
# Used as SessionStart hook with matcher "compact"

if [ -f "$CLAUDE_PROJECT_DIR/project.md" ]; then
  echo "=== PROJECT CONTEXT (reinjected after compaction) ==="
  head -50 "$CLAUDE_PROJECT_DIR/project.md"
  echo ""
fi

if [ -f "$CLAUDE_PROJECT_DIR/CLAUDE.md" ]; then
  echo "=== ARCHITECTURE ==="
  head -80 "$CLAUDE_PROJECT_DIR/CLAUDE.md"
  echo ""
fi

echo "=== WORKFLOW ==="
echo "Reminder: One feature at a time. Stabilize before moving on. Use /next-feature to continue."
echo ""

# Show issue state if gh is available
if command -v gh &> /dev/null; then
  echo "=== ISSUE STATE ==="
  IN_PROGRESS=$(gh issue list --label "in-progress" --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null)
  if [ -n "$IN_PROGRESS" ]; then
    echo "In progress: $IN_PROGRESS"
  fi
  REMAINING=$(gh issue list --label "task" --json number --jq 'length' 2>/dev/null)
  if [ -n "$REMAINING" ]; then
    echo "Remaining: $REMAINING US"
  fi
  echo ""
fi

exit 0
