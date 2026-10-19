#!/usr/bin/env bash
set -euo pipefail

URL="https://stats.aipipe.org/usage.json"
mkdir -p logs/raw

TS=$(date -u +%Y%m%dT%H%M%SZ)
curl -fsS --max-time 30 --retry 3 "$URL" -o "logs/raw/usage-$TS.json"
jq -e '.days' "logs/raw/usage-$TS.json" >/dev/null

CSV="logs/daily.csv"
[ -f "$CSV" ] || echo "date,spend_usd,iitm_users,input_tokens,output_tokens,fetched_at" > "$CSV"

jq -r '.days[] | select(.complete and .available)
       | [.date, .total.spend_usd, (.iitm_users // 0),
          .total.input_tokens, .total.output_tokens] | @csv' \
  "logs/raw/usage-$TS.json" | tr -d '"' |
while IFS= read -r line; do
  if ! cut -d, -f1-5 "$CSV" | grep -qxF -- "$line"; then
    echo "$line,$TS" >> "$CSV"
  fi
done
