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

# Determine default model based on available API keys
# Priority: explicit OPENCLAW_MODEL > OpenCode Zen > MiniMax direct
if [ -n "$OPENCLAW_MODEL" ]; then
  export OPENCLAW_MODEL="$OPENCLAW_MODEL"
elif [ -n "$OPENCODE_API_KEY" ]; then
  export OPENCLAW_MODEL="opencode/minimax-m2.5-free"
elif [ -n "$MINIMAX_API_KEY" ]; then
  export OPENCLAW_MODEL="minimax/MiniMax-M2.1"
else
  export OPENCLAW_MODEL="opencode/minimax-m2.5-free"  # fallback
fi
echo "[openclaw-railway] Using model: $OPENCLAW_MODEL"

# Generate gateway config
export ALLOWED_ORIGIN="${OPENCLAW_ALLOWED_ORIGIN:-https://openclaw-production-d227.up.railway.app}"
envsubst '${ALLOWED_ORIGIN} ${OPENCLAW_MODEL}' < /openclaw.json.template > "$OPENCLAW_STATE_DIR/openclaw.json"

# Set gateway token
if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
  openclaw config set gateway.auth.token "$OPENCLAW_GATEWAY_TOKEN" 2>/dev/null || true
fi

# Set API credentials
# Priority: OpenCode Zen (opencode/*) > MiniMax direct (minimax/*)
mkdir -p "$OPENCLAW_STATE_DIR/credentials"
chmod 700 "$OPENCLAW_STATE_DIR/credentials"

if [ -n "$OPENCODE_API_KEY" ]; then
  echo "[openclaw-railway] Using OpenCode Zen API"
  echo "{\"apiKey\": \"$OPENCODE_API_KEY\"}" > "$OPENCLAW_STATE_DIR/credentials/opencode.json"
  chmod 600 "$OPENCLAW_STATE_DIR/credentials/opencode.json"
fi

if [ -n "$MINIMAX_API_KEY" ]; then
  echo "[openclaw-railway] Using MiniMax direct API"
  echo "{\"apiKey\": \"$MINIMAX_API_KEY\"}" > "$OPENCLAW_STATE_DIR/credentials/minimax.json"
  chmod 600 "$OPENCLAW_STATE_DIR/credentials/minimax.json"
fi

# Harden permissions
chmod 700 "$OPENCLAW_STATE_DIR"

# Doctor check
openclaw doctor --fix --yes 2>/dev/null || true

# Start
exec pm2-runtime /ecosystem.config.js
