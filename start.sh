#!/bin/bash
set -e

echo "=============================================="
echo "[openclaw-railway] Starting OpenClaw Gateway"
echo "=============================================="

# Ensure directories exist
mkdir -p "$OPENCLAW_STATE_DIR" "$OPENCLAW_WORKSPACE_DIR"

# Credentials file for persistence across restarts
CREDS_FILE="$OPENCLAW_STATE_DIR/.credentials"

# Auto-generate or load credentials
if [ -f "$CREDS_FILE" ]; then
  echo "[openclaw-railway] Loading existing credentials..."
  source "$CREDS_FILE"
else
  echo "[openclaw-railway] Generating new credentials..."
fi

# PROXY_USER - default to "openclaw" if not set
if [ -z "$PROXY_USER" ]; then
  PROXY_USER="openclaw"
fi
export PROXY_USER

# PROXY_PASS - auto-generate if not set
if [ -z "$PROXY_PASS" ]; then
  PROXY_PASS=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
fi
export PROXY_PASS

# OPENCLAW_GATEWAY_TOKEN - auto-generate if not set
if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
  OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
fi
export OPENCLAW_GATEWAY_TOKEN

# Save credentials for persistence
cat > "$CREDS_FILE" << EOF
PROXY_USER="$PROXY_USER"
PROXY_PASS="$PROXY_PASS"
OPENCLAW_GATEWAY_TOKEN="$OPENCLAW_GATEWAY_TOKEN"
EOF
chmod 600 "$CREDS_FILE"

# Log credentials prominently
echo ""
echo "=============================================="
echo "  OPENCLAW CREDENTIALS (save these!)"
echo "=============================================="
echo ""
echo "  Basic Auth (for Control UI & Terminal access):"
echo "    Username: $PROXY_USER"
echo "    Password: $PROXY_PASS"
echo ""
echo "  Gateway Token (for API access):"
echo "    $OPENCLAW_GATEWAY_TOKEN"
echo ""
echo "  Web Terminal (ttyd):"
echo "    https://\$RAILWAY_PUBLIC_DOMAIN/terminal"
echo ""
echo "=============================================="
echo ""

# Setup nginx basic auth
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
  export OPENCLAW_MODEL="opencode/minimax-m2.5-free"
fi
echo "[openclaw-railway] Model: $OPENCLAW_MODEL"

# Generate gateway config
# Use Railway's auto-provided domain, or allow override
if [ -n "$OPENCLAW_ALLOWED_ORIGIN" ]; then
  export ALLOWED_ORIGIN="$OPENCLAW_ALLOWED_ORIGIN"
elif [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
  export ALLOWED_ORIGIN="https://$RAILWAY_PUBLIC_DOMAIN"
else
  export ALLOWED_ORIGIN="*"
fi
echo "[openclaw-railway] Allowed origin: $ALLOWED_ORIGIN"
envsubst '${ALLOWED_ORIGIN} ${OPENCLAW_MODEL}' < /openclaw.json.template > "$OPENCLAW_STATE_DIR/openclaw.json"

# Set gateway token
openclaw config set gateway.auth.token "$OPENCLAW_GATEWAY_TOKEN" 2>/dev/null || true

# Set API credentials
mkdir -p "$OPENCLAW_STATE_DIR/credentials"
chmod 700 "$OPENCLAW_STATE_DIR/credentials"

if [ -n "$OPENCODE_API_KEY" ]; then
  echo "[openclaw-railway] API: OpenCode Zen"
  echo "{\"apiKey\": \"$OPENCODE_API_KEY\"}" > "$OPENCLAW_STATE_DIR/credentials/opencode.json"
  chmod 600 "$OPENCLAW_STATE_DIR/credentials/opencode.json"
fi

if [ -n "$MINIMAX_API_KEY" ]; then
  echo "[openclaw-railway] API: MiniMax direct"
  echo "{\"apiKey\": \"$MINIMAX_API_KEY\"}" > "$OPENCLAW_STATE_DIR/credentials/minimax.json"
  chmod 600 "$OPENCLAW_STATE_DIR/credentials/minimax.json"
fi

# Configure Telegram if bot token is provided
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  echo "[openclaw-railway] Telegram: Configuring bot..."
  
  # Enable telegram plugin
  openclaw plugins enable telegram 2>/dev/null || true
  
  # Set bot token in config
  openclaw config set channels.telegram.enabled true 2>/dev/null || true
  openclaw config set channels.telegram.botToken "$TELEGRAM_BOT_TOKEN" 2>/dev/null || true
  openclaw config set channels.telegram.dmPolicy "pairing" 2>/dev/null || true
  
  # Pre-approve Telegram user if TELEGRAM_ALLOW_FROM is set
  if [ -n "$TELEGRAM_ALLOW_FROM" ]; then
    echo "[openclaw-railway] Telegram: Pre-approving user: $TELEGRAM_ALLOW_FROM"
    
    cat > "$OPENCLAW_STATE_DIR/credentials/telegram-default-allowFrom.json" << EOF
{
  "version": 1,
  "allowFrom": ["$TELEGRAM_ALLOW_FROM"]
}
EOF
    chmod 600 "$OPENCLAW_STATE_DIR/credentials/telegram-default-allowFrom.json"
    
    # Initialize empty pairing requests
    cat > "$OPENCLAW_STATE_DIR/credentials/telegram-pairing.json" << EOF
{
  "version": 1,
  "requests": []
}
EOF
    chmod 600 "$OPENCLAW_STATE_DIR/credentials/telegram-pairing.json"
  fi
  
  echo "[openclaw-railway] Telegram: Bot configured"
fi

# Harden permissions
chmod 700 "$OPENCLAW_STATE_DIR"

# Doctor check
openclaw doctor --fix --yes 2>/dev/null || true

echo "[openclaw-railway] Starting services..."
exec pm2-runtime /ecosystem.config.js
