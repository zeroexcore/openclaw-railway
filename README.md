# OpenClaw on Railway

Deploy your own AI assistant that you can chat with on Telegram.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/7BxENC?referralCode=ExIdPd&utm_medium=integration&utm_source=template&utm_campaign=generic)

## Before You Start

You'll need to set up a few accounts and grab some tokens. This takes about 10 minutes.

### 1. Create a Railway Account

1. Go to [railway.com](https://railway.com) and sign up
2. Add a payment method (required for deployments, but this template uses minimal resources)

### 2. Get Your OpenCode Zen API Key (Free)

This powers the AI. Free tier available for 7 days.

1. Go to [opencode.ai/auth](https://opencode.ai/auth)
2. Sign in and create an API key
3. Copy the key (starts with `sk-...`)

### 3. Create a Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts to name your bot
3. Copy the bot token (looks like `123456789:ABCdefGHI...`)

### 4. Get Your Telegram User ID

1. Open Telegram and search for [@userinfobot](https://t.me/userinfobot)
2. Send any message to it
3. Copy your numeric user ID

## Deploy

1. Click the **Deploy on Railway** button above
2. Fill in the variables:

| Variable | What to enter |
|----------|---------------|
| `OPENCODE_API_KEY` | Your OpenCode Zen API key |
| `TELEGRAM_BOT_TOKEN` | Your bot token from BotFather |
| `TELEGRAM_ALLOW_FROM` | Your Telegram user ID |

3. Click **Deploy**
4. Wait 2-3 minutes for the build to complete

## Start Chatting

Once deployed, open Telegram and send a message to your bot. It should respond!

Your credentials (username/password for the web dashboard) will appear in the deployment logs.

## Need Help?

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [Railway Documentation](https://docs.railway.com)
