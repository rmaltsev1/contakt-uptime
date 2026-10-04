#!/usr/bin/env bash
# Uptime check for contactmeister.de. Prints one line per failed check and exits 1 if any failed.
# Each check gets 3 tries, 20 s apart, so a single slow response doesn't raise an alarm.
set -uo pipefail

SITE="${SITE:-contactmeister.de}"
CERT_MIN_DAYS="${CERT_MIN_DAYS:-14}"
failures=()

try() { # try <description> <command…>
  local what="$1"; shift
  for attempt in 1 2 3; do
    if "$@"; then return 0; fi
    [ "$attempt" -lt 3 ] && sleep 20
  done
  failures+=("$what")
}

home_ok() {
  local body
  body="$(curl -fsS --max-time 15 "https://$SITE/")" && grep -q "CONTACT" <<<"$body"
}

www_redirects() {
  local out
  out="$(curl -sS -o /dev/null --max-time 15 -w '%{http_code} %{redirect_url}' "https://www.$SITE/")"
  [ "$out" = "301 https://$SITE/" ]
}

backend_ok() {
  curl -fsS --max-time 15 "https://$SITE/api/health" 2>/dev/null | grep -q '"ok":true'
}

cert_valid() {
  echo | openssl s_client -connect "$SITE:443" -servername "$SITE" 2>/dev/null |
    openssl x509 -noout -checkend $(( CERT_MIN_DAYS * 86400 )) >/dev/null 2>&1
}

try "Сайт https://$SITE не открывается" home_ok
try "www.$SITE не перенаправляет на $SITE" www_redirects
try "Заявки/бот не работают (/api/health: бэкенд, база или Telegram)" backend_ok
try "SSL-сертификат истекает меньше чем через $CERT_MIN_DAYS дней" cert_valid

for f in "${failures[@]+"${failures[@]}"}"; do echo "$f"; done
[ "${#failures[@]}" -eq 0 ]
