#!/bin/bash
set -e

echo "[openclaw-railway] Starting OpenClaw Gateway..."
echo "[openclaw-railway] State dir: $OPENCLAW_STATE_DIR"
echo "[openclaw-railway] Workspace: $OPENCLAW_WORKSPACE_DIR"

# Ensure directories exist
mkdir -p "$OPENCLAW_STATE_DIR" "$OPENCLAW_WORKSPACE_DIR"

# Setup nginx basic auth if credentials provided
if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
  echo "[openclaw-railway] Configuring nginx with basic auth..."
  htpasswd -cb /etc/nginx/.htpasswd "$PROXY_USER" "$PROXY_PASS"
  AUTH_BLOCK='auth_basic "OpenClaw Gateway";
        auth_basic_user_file /etc/nginx/.htpasswd;'
else
  echo "[openclaw-railway] WARNING: No PROXY_USER/PROXY_PASS set - proxy has no auth!"
  AUTH_BLOCK=""
fi

# Configure nginx as reverse proxy with WebSocket support
cat > /etc/nginx/sites-available/default << EOF
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 8080;
    
    # Health check endpoint (no auth for Railway healthcheck)
    location /health {
        return 200 'ok';
        add_header Content-Type text/plain;
    }
    
    location / {
        $AUTH_BLOCK
        
        proxy_pass http://127.0.0.1:18789;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}
EOF

# Determine allowed origins for Control UI
ALLOWED_ORIGIN="${OPENCLAW_ALLOWED_ORIGIN:-https://openclaw-production-d227.up.railway.app}"

# Create gateway config
echo "[openclaw-railway] Creating gateway config..."
echo "[openclaw-railway] Allowed origin: $ALLOWED_ORIGIN"
cat > "$OPENCLAW_STATE_DIR/openclaw.json" << EOF
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
    "trustedProxies": ["127.0.0.1"],
    "controlUi": {
      "allowedOrigins": ["$ALLOWED_ORIGIN"]
    }
  },
  "agents": {
    "defaults": {
      "model": "minimax/MiniMax-M2.1",
      "workspace": "/data/workspace"
    }
  }
}
EOF

# Set gateway token from env if provided
if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
  echo "[openclaw-railway] Setting gateway token..."
  openclaw config set gateway.auth.token "$OPENCLAW_GATEWAY_TOKEN" 2>/dev/null || true
fi

# Set MiniMax API key if provided
if [ -n "$MINIMAX_API_KEY" ]; then
  echo "[openclaw-railway] Setting MiniMax credentials..."
  mkdir -p "$OPENCLAW_STATE_DIR/credentials"
  echo "{\"apiKey\": \"$MINIMAX_API_KEY\"}" > "$OPENCLAW_STATE_DIR/credentials/minimax.json"
  chmod 700 "$OPENCLAW_STATE_DIR/credentials"
  chmod 600 "$OPENCLAW_STATE_DIR/credentials/minimax.json"
fi

# Harden state directory permissions
echo "[openclaw-railway] Hardening permissions..."
chmod 700 "$OPENCLAW_STATE_DIR"

# Check for updates on startup (non-blocking)
echo "[openclaw-railway] Checking for updates..."
openclaw update status || true

# Run doctor to fix any config issues
echo "[openclaw-railway] Running doctor..."
openclaw doctor --fix --yes 2>/dev/null || true

# Start services with pm2
echo "[openclaw-railway] Starting services with pm2..."
exec pm2-runtime /ecosystem.config.js
