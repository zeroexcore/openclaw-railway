#!/bin/bash
set -e

echo "[openclaw-railway] Starting OpenClaw Gateway..."

# Ensure directories exist
mkdir -p "$OPENCLAW_STATE_DIR" "$OPENCLAW_WORKSPACE_DIR"

# Setup nginx basic auth (required)
if [ -z "$PROXY_USER" ] || [ -z "$PROXY_PASS" ]; then
  echo "[openclaw-railway] ERROR: PROXY_USER and PROXY_PASS are required"
  exit 1
fi
htpasswd -cb /etc/nginx/.htpasswd "$PROXY_USER" "$PROXY_PASS"

# Copy nginx config
cp /nginx.conf.template /etc/nginx/sites-available/default

# Generate gateway config
export ALLOWED_ORIGIN="${OPENCLAW_ALLOWED_ORIGIN:-https://openclaw-production-d227.up.railway.app}"
envsubst '${ALLOWED_ORIGIN} ${OPENCLAW_MODEL}' < /openclaw.json.template > "$OPENCLAW_STATE_DIR/openclaw.json"

# Set gateway token
if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
  openclaw config set gateway.auth.token "$OPENCLAW_GATEWAY_TOKEN" 2>/dev/null || true
fi

# Set MiniMax API key
if [ -n "$MINIMAX_API_KEY" ]; then
  mkdir -p "$OPENCLAW_STATE_DIR/credentials"
  echo "{\"apiKey\": \"$MINIMAX_API_KEY\"}" > "$OPENCLAW_STATE_DIR/credentials/minimax.json"
  chmod 700 "$OPENCLAW_STATE_DIR/credentials"
  chmod 600 "$OPENCLAW_STATE_DIR/credentials/minimax.json"
fi

# Harden permissions
chmod 700 "$OPENCLAW_STATE_DIR"

# Doctor check
openclaw doctor --fix --yes 2>/dev/null || true

# Start
exec pm2-runtime /ecosystem.config.js
