---
name: init-project
description: Initialize a new project. Reads project.md, creates GitHub issues, configures labels. Run this skill at the start of each project.
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(gh *), Bash(bash scripts/*)
---

You initialize the project. Follow these steps in order:

## Project context
!`cat project.md 2>/dev/null || echo "ERROR: project.md missing. Create it first."`

## Initialization steps

### 1. Validate project.md
- Verify all sections are filled (no placeholders)
- Verify US are in the correct format: `- [US-XX] Title | Description | Priority`
- If sections are incomplete, ask the user to fill them

### 2. Create GitHub labels
```bash
gh label create "task" --description "US not started" --color "0075ca" --force
gh label create "in-progress" --description "US in progress" --color "e4e669" --force
gh label create "done" --description "US completed and stabilized" --color "0e8a16" --force
gh label create "bug" --description "Bug detected" --color "d73a4a" --force
gh label create "blocked" --description "US blocked" --color "b60205" --force
gh label create "high" --description "High priority" --color "d93f0b" --force
gh label create "medium" --description "Medium priority" --color "fbca04" --force
gh label create "low" --description "Low priority" --color "c5def5" --force
```

### 3. Create GitHub issues
For each US in project.md, create an issue with:
- Title: `[US-XX] Title`
- Body: Description + assigned agent team + priority
- Labels: `task` + priority label

### 4. Confirm initialization
List all created issues with `gh issue list`.
Display a summary: number of US, priority distribution, next US to work on.
