---
name: next-feature
description: Takes the next US and executes the full workflow (assign team -> implement -> stabilize -> done -> clean context). Dequeues features one by one.
user-invocable: true
---

You dequeue the next feature. Follow the sequential workflow.

## Current state
!`gh issue list --label "task" --json number,title,labels --jq '.[] | "[#\(.number)] \(.title) [\(.labels | map(.name) | join(", "))]"' 2>/dev/null || echo "Cannot list issues"`
!`gh issue list --label "in-progress" --json number,title --jq '.[] | "[#\(.number)] \(.title) -- IN PROGRESS"' 2>/dev/null || echo ""`

## Available agent team
@.claude/skills/orchestrateur/SKILL.md
@.claude/skills/backend-dev/SKILL.md
@.claude/skills/frontend-dev/SKILL.md
@.claude/skills/admin-sys/SKILL.md
@.claude/skills/devops/SKILL.md
@.claude/skills/testeur/SKILL.md
@.claude/skills/reviewer/SKILL.md
@.claude/skills/stabilizer/SKILL.md
@.claude/skills/manager/SKILL.md

## Workflow for the next feature

### 1. Select the next US
- Take the first issue with the `task` label (high priority first)
- If there's an `in-progress` issue, resume it first

### 2. Start the feature
```bash
gh issue edit <number> --add-label "in-progress" --remove-label "task"
```

### 3. Identify the team
- Read the issue body for the assigned team
- Execute each agent in the defined order

### 4. Execute the agent pipeline

**If orchestrator assigned:**
- Decompose the US, propose a plan

**If backend-dev assigned:**
- Implement backend changes

**If frontend-dev assigned:**
- Implement frontend changes

**If admin-sys assigned:**
- Configure infrastructure, security

**If devops assigned:**
- CI/CD, Docker build, deploy

**If tester assigned:**
- Write and run tests

**If reviewer assigned:**
- Code review: quality + security

**stabilizer (ALWAYS last):**
- Syntax + Server + Build + Tests
- Fix until everything passes

### 5. Complete the feature
```bash
gh issue edit <number> --add-label "done" --remove-label "in-progress"
gh issue close <number>
```

### 6. Feature summary
```
## US-XX -- [Title]
- Modified files: [list]
- Tests added: [list]
- Deploy: [status]
- Attention points: [notes]
```

### 7. Clean context
Use `/compact` with this summary to clean context before the next feature.
