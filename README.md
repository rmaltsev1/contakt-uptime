# contakt-uptime

Uptime check for [contactmeister.de](https://contactmeister.de). Every 10 minutes GitHub Actions checks:

- the home page loads,
- `www.contactmeister.de` redirects to `contactmeister.de`,
- `/api/health` is ok (website → backend → database → Telegram bot receiving),
- the TLS certificate is valid for at least 14 more days.

When something breaks, a Telegram message goes to `TELEGRAM_CHAT_ID`; it's repeated every 6 hours while the
problem lasts, and a "back up" message follows when it's fixed. It runs here, outside the server, so it also
reports a server that is completely down.

This repository is public on purpose: public repositories get unlimited free Actions minutes. It contains no
secrets; the bot token and chat id are repository secrets.

| Secret | Value |
| --- | --- |
| `TELEGRAM_BOT_TOKEN` | the CONTACT bot's token (same as `TELEGRAM_BOT_TOKEN` in `/opt/contakt/.env`) |
| `TELEGRAM_CHAT_ID` | the chat that gets alerts |

Run it by hand: Actions → Uptime → Run workflow. Locally: `./check.sh` (prints failed checks, exit 1 if any).

The site and server live in the private repos `contakt-service-frontend` and `contakt-service-backend`.
