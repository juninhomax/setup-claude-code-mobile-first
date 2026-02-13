# Mobile Access Guide

## Accessing from iPhone/iPad

### Option 1: VS Code web (Safari)

1. Open Safari on your iPhone
2. Go to `http://<your-server-ip>:8080/`
3. Enter your `WEB_PASSWORD`
4. Full VS Code experience in the browser

**Tips for Safari:**
- Add to Home Screen for a full-screen app-like experience
- Use the integrated terminal in VS Code to access tmux
- The tmux prefix is `Ctrl+A` (easier to type on mobile than `Ctrl+B`)

### Option 2: SSH client app

Recommended apps:
- **Termius** (free tier available)
- **Blink Shell** (paid, best terminal)
- **a-Shell** (free, basic)

Connect via SSH:
```
ssh user@<your-server-ip>
# or via Tailscale:
ssh user@<hostname>
```

Then attach to the tmux session:
```
tmux attach -t claude-agents
```

### Option 3: Tailscale (recommended for security)

1. Install Tailscale on your iPhone (App Store)
2. Login with the same account as your server
3. Access via Tailscale IP (no public ports needed!)
4. All services accessible securely on the VPN

## tmux on mobile

### Useful shortcuts

| Action | Shortcut | Mobile tip |
|--------|----------|------------|
| Switch to agent N | `Ctrl+A, N` | Use number row |
| Next agent | `Ctrl+A, n` | Quick navigation |
| Previous agent | `Ctrl+A, p` | Quick navigation |
| Tree view | `Ctrl+A, w` | Best for overview |
| Next (alt) | `Ctrl+A, Tab` | Easier on mobile |
| Scroll up | `Ctrl+A, [` | Then use arrows |
| Detach | `Ctrl+A, d` | Session persists |

### Mobile keyboard tips

- Use an external Bluetooth keyboard for the best experience
- On iPad, the Smart Keyboard works well
- On iPhone, use the `Ctrl` key from the extended keyboard (hold globe/emoji key)
- Consider installing a keyboard app with proper Ctrl key support

## Troubleshooting mobile access

### Safari shows "Not Secure"
- Expected when accessing via HTTP (default setup)
- Use Tailscale VPN for secure access without exposing ports publicly

### Connection drops
- tmux preserves your session — just reconnect
- Use `tmux attach -t claude-agents` after reconnecting

### Small screen layout
- The tmux status bar shows all agent tabs
- Use tree view (`Ctrl+A, w`) for easier navigation
- VS Code web has a responsive layout that works on phones
