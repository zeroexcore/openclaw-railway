FROM node:22-slim

# Install dependencies (nginx for auth proxy, apache2-utils for htpasswd)
RUN apt-get update && apt-get install -y git curl nginx apache2-utils && rm -rf /var/lib/apt/lists/*

# Setup pnpm
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@latest --activate && \
    mkdir -p $PNPM_HOME

# Install OpenClaw and pm2 globally
RUN npm install -g openclaw@latest pm2

# Set up directories
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/workspace

# Create data directory
RUN mkdir -p /data/.openclaw /data/workspace

WORKDIR /data

# Expose gateway port
EXPOSE 8080

# Copy startup files
COPY start.sh /start.sh
COPY ecosystem.config.js /ecosystem.config.js
RUN chmod +x /start.sh

CMD ["/start.sh"]
