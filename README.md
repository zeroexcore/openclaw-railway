# OpenClaw Railway Template

Deploy OpenClaw AI agent gateway on Railway with security hardening and process management.

## Features

- **nginx reverse proxy** with basic auth (required)
- **pm2 process manager** for resilience
- Gateway bound to loopback (secure)
- Health endpoint at `/health`
- Volume persistence at `/data`
- Supports OpenCode Zen and MiniMax direct APIs
- Auto-updates on startup

## Quick Deploy

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/7BxENC?referralCode=ExIdPd&utm_medium=integration&utm_source=template&utm_campaign=generic)

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
| `OPENCODE_API_KEY` | - | OpenCode Zen API key (recommended, free tier available) |
| `MINIMAX_API_KEY` | - | MiniMax direct API key (fallback) |
| `OPENCLAW_MODEL` | auto | Override model (e.g., `opencode/minimax-m2.5-free`) |
| `TELEGRAM_BOT_TOKEN` | - | Telegram bot token from @BotFather |
| `TELEGRAM_ALLOW_FROM` | - | Pre-approved Telegram user ID |
| `OPENCLAW_ALLOWED_ORIGIN` | Railway URL | Control UI allowed origin |
| `OPENCLAW_STATE_DIR` | `/data/.openclaw` | Config storage |
| `OPENCLAW_WORKSPACE_DIR` | `/data/workspace` | Agent workspace |

### Telegram Setup

Set `TELEGRAM_BOT_TOKEN` and optionally `TELEGRAM_ALLOW_FROM` to have Telegram ready on first deploy:

```bash
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_ALLOW_FROM=572012316
```

Get your Telegram user ID by messaging [@userinfobot](https://t.me/userinfobot).

### Model Selection

The template auto-selects the model based on available API keys:
1. If `OPENCODE_API_KEY` is set → uses `opencode/minimax-m2.5-free`
2. If `MINIMAX_API_KEY` is set → uses `minimax/MiniMax-M2.1`
3. Override with `OPENCLAW_MODEL` env var

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
