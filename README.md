# OpenClaw Railway Template

Deploy OpenClaw on Railway with security hardening and process management.

## Features

- **nginx reverse proxy** with basic auth
- **pm2 process manager** for resilience
- Gateway bound to loopback (secure)
- Health endpoint at `/health`
- Volume persistence at `/data`
- Auto-updates on startup

## Quick Deploy

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template?template=https://github.com/zeroexcore/openclaw-railway)

Or manually:
```bash
railway init --name openclaw
railway link
railway add --repo zeroexcore/openclaw-railway
railway volume add --mount-path /data
railway domain --port 8080
```

## Required Variables

| Variable | Description |
|----------|-------------|
| `PROXY_USER` | Basic auth username |
| `PROXY_PASS` | Basic auth password |
| `OPENCLAW_GATEWAY_TOKEN` | Gateway API token (64 char hex) |

## Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MINIMAX_API_KEY` | - | MiniMax LLM API key |
| `OPENCLAW_ALLOWED_ORIGIN` | Railway URL | Control UI allowed origin |
| `OPENCLAW_STATE_DIR` | `/data/.openclaw` | Config storage |
| `OPENCLAW_WORKSPACE_DIR` | `/data/workspace` | Agent workspace |

## Generate Credentials

```bash
# Generate gateway token
openssl rand -hex 32

# Generate proxy password  
openssl rand -base64 24
```

## After Deploy

1. Access Control UI at `https://your-domain.up.railway.app`
2. Login with basic auth credentials
3. Approve device pairing when prompted
4. Configure model/channels via CLI:

```bash
railway ssh -- "openclaw plugins enable telegram"
railway ssh -- "openclaw channels add --channel telegram --token <BOT_TOKEN>"
railway ssh -- "pm2 restart openclaw"
```

## Architecture

```
Internet → nginx:8080 (basic auth) → openclaw:18789 (loopback)
                                   ↑
                              pm2 manages both
```

## Troubleshooting

```bash
# Check status
railway ssh -- "pm2 status"

# View logs
railway ssh -- "pm2 logs openclaw --lines 50"

# Restart cleanly
railway ssh -- "pm2 restart openclaw"

# Security audit
railway ssh -- "openclaw security audit"
```
