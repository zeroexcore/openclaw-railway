module.exports = {
  apps: [
    {
      name: 'nginx',
      script: '/usr/sbin/nginx',
      args: '-g "daemon off;"',
      interpreter: 'none',
      autorestart: true,
      watch: false,
    },
    {
      name: 'openclaw',
      script: '/usr/local/bin/openclaw',
      args: 'gateway --port 18789 --bind loopback',
      interpreter: 'none',
      autorestart: true,
      watch: false,
      restart_delay: 3000,
      max_restarts: 10,
      env: {
        OPENCLAW_STATE_DIR: '/data/.openclaw',
        OPENCLAW_WORKSPACE_DIR: '/data/workspace',
      },
    },
    {
      name: 'vibetunnel',
      script: '/usr/local/bin/vibetunnel',
      args: '--port 4030 --bind 127.0.0.1 --no-auth',
      interpreter: 'none',
      autorestart: true,
      watch: false,
      restart_delay: 3000,
      max_restarts: 10,
      env: {
        HOME: '/data',
        VIBETUNNEL_LOG_LEVEL: 'error',
      },
    },
  ],
};
