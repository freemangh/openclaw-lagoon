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
    apiKey: '${ANTHROPIC_API_KEY}',
    baseUrl: 'https://api.anthropic.com',
    models: [
      { id: 'claude-opus-4-6', name: 'Claude Opus 4.6', contextWindow: 200000, maxTokens: 32000, input: ['text'], cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } },
      { id: 'claude-sonnet-4-5-20250929', name: 'Claude Sonnet 4.5', contextWindow: 200000, maxTokens: 16384, input: ['text'], cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } },
      { id: 'claude-haiku-4-5-20251001', name: 'Claude Haiku 4.5', contextWindow: 200000, maxTokens: 8192, input: ['text'], cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } }
    ]
  };
  console.log('[provider-config] Configured Anthropic provider');
}

// Configure OpenAI if API key is set
if (process.env.OPENAI_API_KEY) {
  config.models.providers.openai = {
    apiKey: '${OPENAI_API_KEY}',
    baseUrl: 'https://api.openai.com/v1',
    api: 'openai-completions',
    models: [
      { id: 'gpt-5.2', name: 'GPT-5.2', contextWindow: 128000, maxTokens: 16384, input: ['text'], cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } },
      { id: 'gpt-4.1', name: 'GPT-4.1', contextWindow: 128000, maxTokens: 16384, input: ['text'], cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } },
      { id: 'gpt-4o', name: 'GPT-4o', contextWindow: 128000, maxTokens: 16384, input: ['text'], cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } },
      { id: 'o3-mini', name: 'o3-mini', reasoning: true, contextWindow: 200000, maxTokens: 100000, input: ['text'], cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } }
    ]
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
