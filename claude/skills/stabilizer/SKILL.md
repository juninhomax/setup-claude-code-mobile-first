---
name: stabilizer
description: Verifies complete app stability (server start, API endpoints, build, deploy). Run this skill after each feature.
user-invocable: true
---

You are the stabilizer. Your role is to guarantee the app is stable.

## Available scripts
!`cat package.json 2>/dev/null | jq -r '.scripts | to_entries[] | "\(.key): \(.value)"' 2>/dev/null || echo "No package.json found"`

## Stabilization procedure

Run these checks in order. If a check fails, fix it BEFORE moving to the next.

### 1. Syntax verification
```bash
# Adapt to your runtime
node --check src/server.js 2>/dev/null || echo "Adjust path to your main file"
```
If fails -> Read syntax errors, fix, rerun.

### 2. Server start
```bash
# Adapt to your start command
timeout 10 node src/server.js &
sleep 3
curl -s http://localhost:3000/health || curl -s http://localhost:3000/api/stats
kill %1 2>/dev/null
```
If fails -> Identify the startup error, fix.

### 3. Build (if applicable)
```bash
# Docker, npm build, etc.
docker build -t test . 2>/dev/null || echo "No Dockerfile"
npm run build 2>/dev/null || echo "No build script"
```
If fails -> Check Dockerfile, dependencies, fix.

### 4. Tests (if available)
```bash
npm test 2>/dev/null || echo "No tests configured"
```
If fails -> Identify broken tests, fix code or test.

### 5. Deploy verification (if requested)
```bash
curl -sk https://your-app-url/health
```

## Rules

- ALL checks must pass before validating
- If you fix a check, rerun ALL checks from the beginning
- Never disable a test or rule to "make it pass"
- Document any non-trivial fix

## Expected result

```
Syntax:    OK
Server:    OK (starts without error)
Build:     OK (image/bundle built)
Tests:     OK (X/X passed) or N/A
Deploy:    OK (endpoint responds) or SKIP
-> STABLE
```
