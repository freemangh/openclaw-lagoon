#!/bin/sh
echo "[provider-config] Configuring OpenClaw for direct provider access..."

node << 'EOFNODE'
const fs = require('fs');
const path = require('path');

const stateDir = process.env.OPENCLAW_STATE_DIR || path.join(process.env.HOME || '/home', '.openclaw');
const configPath = path.join(stateDir, 'openclaw.json');

fs.mkdirSync(stateDir, { recursive: true });

const config = {
  agents: {
    defaults: {
      model: {
        primary: process.env.OPENCLAW_DEFAULT_MODEL || 'anthropic/claude-opus-4-6'
      },
      workspace: process.env.OPENCLAW_WORKSPACE || '/home/.openclaw/workspace'
    }
  },
  models: {
    providers: {}
  },
  gateway: {
    port: parseInt(process.env.OPENCLAW_GATEWAY_PORT, 10) || 3000,
    mode: 'local'
  },
  channels: {},
  tools: {
    alsoAllow: ['lobster']
  }
};

// Configure Anthropic if API key is set
if (process.env.ANTHROPIC_API_KEY) {
  config.models.providers.anthropic = {
    apiKey: '${ANTHROPIC_API_KEY}'
  };
  console.log('[provider-config] Configured Anthropic provider');
}

// Configure OpenAI if API key is set
if (process.env.OPENAI_API_KEY) {
  config.models.providers.openai = {
    apiKey: '${OPENAI_API_KEY}'
  };
  console.log('[provider-config] Configured OpenAI provider');
}

// Configure channels
if (process.env.SLACK_BOT_TOKEN && process.env.SLACK_APP_TOKEN) {
  config.channels.slack = {
    botToken: '${SLACK_BOT_TOKEN}',
    appToken: '${SLACK_APP_TOKEN}',
    enabled: true
  };
  console.log('[provider-config] Configured Slack channel');
}

if (process.env.DISCORD_BOT_TOKEN) {
  config.channels.discord = {
    token: '${DISCORD_BOT_TOKEN}',
    enabled: true
  };
  console.log('[provider-config] Configured Discord channel');
}

if (process.env.TELEGRAM_BOT_TOKEN) {
  config.channels.telegram = {
    botToken: '${TELEGRAM_BOT_TOKEN}',
    enabled: true
  };
  console.log('[provider-config] Configured Telegram channel');
}

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log('[provider-config] Configuration saved to:', configPath);
EOFNODE

echo "[provider-config] Configuration complete."
