#!/usr/bin/env bash
# Decides whether to message Telegram, based on the previous state (state/status, restored from the Actions cache).
#   up → down:   alert with the failed checks
#   down → down: repeat every REPEAT_HOURS
#   down → up:   "back up" with the downtime
# Needs TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID. Usage: notify.sh <check exit code> <check output file>
set -euo pipefail

code="$1"; output="$2"
REPEAT_HOURS="${REPEAT_HOURS:-6}"
mkdir -p state
prev="up"; since=0; last_alert=0
[ -f state/status ] && read -r prev since last_alert < state/status || true
now="$(date +%s)"

send() {
  curl -fsS --max-time 20 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=$1" \
    --data-urlencode "disable_web_page_preview=true" >/dev/null
}

minutes() { echo $(( ($1) / 60 )); }

if [ "$code" -ne 0 ]; then
  details="$(sed 's/^/• /' "$output")"
  if [ "$prev" = "up" ]; then
    send "🔴 contactmeister.de: проблема
$details"
    echo "down $now $now" > state/status
  elif [ $(( now - last_alert )) -ge $(( REPEAT_HOURS * 3600 )) ]; then
    send "🔴 contactmeister.de: всё ещё проблема ($(minutes "now - since") мин)
$details"
    echo "down $since $now" > state/status
  else
    echo "down $since $last_alert" > state/status
  fi
else
  if [ "$prev" = "down" ]; then
    send "✅ contactmeister.de снова работает (сбой длился ~$(minutes "now - since") мин)"
  fi
  echo "up $now 0" > state/status
fi
cat state/status
