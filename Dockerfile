FROM node:22-slim

# Cache bust: 2026-02-28-v6
# Install dependencies (nginx-full for sub_filter module)
RUN apt-get update && apt-get install -y git curl nginx-full apache2-utils gettext-base && rm -rf /var/lib/apt/lists/*

# Setup pnpm
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@latest --activate && \
    mkdir -p $PNPM_HOME

# Install OpenClaw and pm2 globally
RUN npm install -g openclaw@latest pm2

# Install ttyd (prebuilt binary) for web terminal
RUN curl -L https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

# Set up directories
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/workspace

# Create data directory
RUN mkdir -p /data/.openclaw /data/workspace

WORKDIR /data

# Expose gateway port
EXPOSE 8080

# Copy config templates and startup files
COPY nginx.conf.template /nginx.conf.template
COPY openclaw.json.template /openclaw.json.template
COPY ecosystem.config.js /ecosystem.config.js
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
