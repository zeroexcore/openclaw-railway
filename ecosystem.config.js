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
      name: 'ttyd',
      script: '/usr/local/bin/ttyd',
      args: '-p 4030 -i 127.0.0.1 -W /bin/bash',
      interpreter: 'none',
      autorestart: true,
      watch: false,
      restart_delay: 3000,
      max_restarts: 10,
      cwd: '/data/workspace',
    },
  ],
};
