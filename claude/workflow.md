# Sequential workflow

## Core principle

**One feature at a time. Stabilize before moving on.**

## Feature lifecycle

```
[task] -> [in-progress] -> [implement] -> [stabilize] -> [done] -> [clean context]
```

### Step 1: Selection
- Take the first `task` issue by priority (high > medium > low)
- If there's an `in-progress` issue, resume it first
- Command: `gh issue list --label "task"`

### Step 2: Start
- Move issue to `in-progress`
- Command: `gh issue edit <N> --add-label "in-progress" --remove-label "task"`

### Step 3: Team identification
- Read the issue body for the assigned team
- Execute agents in the defined order

### Step 4: Agent pipeline
Standard order:
1. `/orchestrateur` — Planning (if assigned)
2. `/backend-dev` — Backend implementation
3. `/frontend-dev` — Frontend implementation
4. `/admin-sys` — Infrastructure (if assigned)
5. `/devops` — CI/CD and deploy (if assigned)
6. `/testeur` — Tests (if assigned)
7. `/reviewer` — Review (if assigned)
8. `/stabilizer` — **ALWAYS last**

### Step 5: Stabilization
The stabilizer verifies:
- [ ] Syntax OK
- [ ] Server starts without error
- [ ] Build passes
- [ ] Tests pass (if available)
- [ ] Deploy OK (if requested)

If a check fails -> fix -> rerun ALL checks.

### Step 6: Closure
- Move issue to `done` and close
- Command: `gh issue edit <N> --add-label "done" --remove-label "in-progress" && gh issue close <N>`

### Step 7: Cleanup
- Produce a feature summary
- Use `/compact` to clean context
- The `reinject-context.sh` hook reinjects essential context

## GitHub labels

| Label | Description | Color |
|-------|-------------|-------|
| `task` | US not started | blue |
| `in-progress` | US in progress | yellow |
| `done` | US completed and stabilized | green |
| `bug` | Bug detected | red |
| `blocked` | US blocked | dark red |
| `high` | High priority | orange |
| `medium` | Medium priority | yellow |
| `low` | Low priority | light blue |

## Useful commands

```bash
# View issues
gh issue list
gh issue list --label "task"
gh issue list --label "in-progress"

# Create an issue
gh issue create --title "[US-XX] Title" --body "Description" --label "task,high"
```
