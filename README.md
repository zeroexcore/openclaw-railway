# OpenClaw Railway Template

Deploy OpenClaw on Railway with sane defaults.

## Features

- Installs OpenClaw via pnpm (always latest stable)
- Auto-updates check on startup
- Clean minimal config
- Volume persistence at `/data`

## Quick Deploy

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/YOUR_TEMPLATE_CODE)

## Required Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENCLAW_GATEWAY_TOKEN` | Gateway auth token (generate a random string) | Yes |

## Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_STATE_DIR` | `/data/.openclaw` | Config storage |
| `OPENCLAW_WORKSPACE_DIR` | `/data/workspace` | Agent workspace |

## Volume

Mount a volume at `/data` for persistence.

## After Deploy

1. Get your Railway domain from Settings → Domains
2. Access the gateway at `https://your-domain.up.railway.app`
3. Configure via `openclaw` CLI or Control UI

## Authentication

The gateway uses token auth. Set `OPENCLAW_GATEWAY_TOKEN` and use it to authenticate API requests.
# Wed Feb 25 17:21:05 +07 2026
