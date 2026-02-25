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
     grep -q '"bind": "lan"' "$OPENCLAW_STATE_DIR/openclaw.json" 2>/dev/null; then
    echo "[openclaw-railway] Found insecure bind config, resetting to loopback..."
    rm -f "$OPENCLAW_STATE_DIR/openclaw.json"
  fi
fi

# Initialize config if it doesn't exist
if [ ! -f "$OPENCLAW_STATE_DIR/openclaw.json" ]; then
  echo "[openclaw-railway] No config found, running initial setup..."
  
  # Create config with loopback binding (secure)
  # External access is via socat proxy on port 8080
  cat > "$OPENCLAW_STATE_DIR/openclaw.json" << 'EOF'
{
  "update": {
    "channel": "stable"
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token"
    },
    "trustedProxies": ["127.0.0.1"]
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

# Start socat proxy: 0.0.0.0:8080 -> 127.0.0.1:18789
# This allows Railway to route traffic while gateway stays on loopback
echo "[openclaw-railway] Starting socat proxy (0.0.0.0:8080 -> 127.0.0.1:18789)..."
socat TCP-LISTEN:8080,fork,reuseaddr TCP:127.0.0.1:18789 &
SOCAT_PID=$!

# Give socat a moment to bind
sleep 1

# Start the gateway on loopback (secure)
echo "[openclaw-railway] Starting gateway on loopback:18789..."
openclaw gateway --port 18789 --bind loopback &
GATEWAY_PID=$!

# Wait for either process to exit
wait -n $SOCAT_PID $GATEWAY_PID

# If one exits, kill the other and exit
echo "[openclaw-railway] Process exited, shutting down..."
kill $SOCAT_PID $GATEWAY_PID 2>/dev/null || true
wait
