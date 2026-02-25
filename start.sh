#!/bin/bash
set -e

echo "[openclaw-railway] Starting OpenClaw Gateway..."
echo "[openclaw-railway] State dir: $OPENCLAW_STATE_DIR"
echo "[openclaw-railway] Workspace: $OPENCLAW_WORKSPACE_DIR"

# Ensure directories exist
mkdir -p "$OPENCLAW_STATE_DIR" "$OPENCLAW_WORKSPACE_DIR"

# Fix any invalid config from previous runs
if [ -f "$OPENCLAW_STATE_DIR/openclaw.json" ]; then
  if grep -q '"bind": "all"' "$OPENCLAW_STATE_DIR/openclaw.json" 2>/dev/null || \
     ! grep -q 'dangerouslyAllowHostHeaderOriginFallback' "$OPENCLAW_STATE_DIR/openclaw.json" 2>/dev/null; then
    echo "[openclaw-railway] Found invalid/incomplete config, resetting..."
    rm -f "$OPENCLAW_STATE_DIR/openclaw.json"
  fi
fi

# Initialize config if it doesn't exist
if [ ! -f "$OPENCLAW_STATE_DIR/openclaw.json" ]; then
  echo "[openclaw-railway] No config found, running initial setup..."
  
  # Create minimal config (bind: lan for container networking)
  cat > "$OPENCLAW_STATE_DIR/openclaw.json" << 'EOF'
{
  "update": {
    "channel": "stable"
  },
  "gateway": {
    "port": 8080,
    "mode": "local",
    "bind": "lan",
    "auth": {
      "mode": "token"
    },
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true
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

# Start the gateway - use "lan" binding for containers (0.0.0.0)
echo "[openclaw-railway] Starting gateway on port 8080..."
exec openclaw gateway --port 8080 --bind lan
