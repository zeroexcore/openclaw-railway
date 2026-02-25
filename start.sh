#!/bin/bash
set -e

echo "[openclaw-railway] Starting OpenClaw Gateway..."
echo "[openclaw-railway] State dir: $OPENCLAW_STATE_DIR"
echo "[openclaw-railway] Workspace: $OPENCLAW_WORKSPACE_DIR"

# Ensure directories exist
mkdir -p "$OPENCLAW_STATE_DIR" "$OPENCLAW_WORKSPACE_DIR"

# Initialize config if it doesn't exist
if [ ! -f "$OPENCLAW_STATE_DIR/openclaw.json" ]; then
  echo "[openclaw-railway] No config found, running initial setup..."
  
  # Create minimal config
  cat > "$OPENCLAW_STATE_DIR/openclaw.json" << 'EOF'
{
  "update": {
    "channel": "stable"
  },
  "gateway": {
    "port": 8080,
    "mode": "local",
    "bind": "0.0.0.0",
    "auth": {
      "mode": "token"
    }
  },
  "agents": {
    "defaults": {
      "workspace": "/data/workspace"
    }
  }
}
EOF
fi

# Set gateway token from env if provided
if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
  echo "[openclaw-railway] Setting gateway token from environment..."
  openclaw config set gateway.auth.token "$OPENCLAW_GATEWAY_TOKEN" 2>/dev/null || true
fi

# Check for updates on startup (non-blocking)
echo "[openclaw-railway] Checking for updates..."
openclaw update status || true

# Run doctor to fix any config issues
echo "[openclaw-railway] Running doctor..."
openclaw doctor --fix --yes 2>/dev/null || true

# Start the gateway
echo "[openclaw-railway] Starting gateway on port 8080..."
exec openclaw gateway --port 8080 --bind 0.0.0.0
