FROM node:22-slim

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install OpenClaw globally via pnpm
RUN pnpm add -g openclaw@latest

# Set up directories
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/workspace

# Create data directory
RUN mkdir -p /data/.openclaw /data/workspace

WORKDIR /data

# Expose gateway port
EXPOSE 8080

# Start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
