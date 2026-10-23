#!/usr/bin/env bash
set -euo pipefail

URL="https://stats.aipipe.org/usage.json"
mkdir -p logs/raw

TS=$(date -u +%Y%m%dT%H%M%SZ)
RAW="logs/raw/usage-$TS.json"
curl -fsS --max-time 30 --retry 3 "$URL" -o "$RAW"
jq -e '.days | type == "array"' "$RAW" >/dev/null

CSV="logs/daily.csv"
HEADER="date,spend_usd,iitm_users,all_domain_users,users_1_provider,users_2_providers,users_3plus_providers,input_tokens,output_tokens,spend_per_all_domain_user_usd,fetched_at"

if [ ! -f "$CSV" ]; then
  echo "$HEADER" > "$CSV"
fi

# Archive completed days only. @tsv avoids CSV quote handling because
# these selected fields contain no tabs/newlines; the date is the row key.
jq -r --arg ts "$TS" '
  .days[]
  | select(.complete == true and .available == true and .total != null)
  | . as $d
  | (($d.users_by_provider_count // {}) | .["1"] // 0) as $u1
  | (($d.users_by_provider_count // {}) | .["2"] // 0) as $u2
  | (($d.users_by_provider_count // {}) | .["3+"] // 0) as $u3
  | ($u1 + $u2 + $u3) as $all
  | [
      $d.date,
      $d.total.spend_usd,
      ($d.iitm_users // 0),
      $all,
      $u1,
      $u2,
      $u3,
      $d.total.input_tokens,
      $d.total.output_tokens,
      (if $all > 0 then ($d.total.spend_usd / $all) else "NA" end),
      $ts
    ] | @tsv
' "$RAW" | while IFS=$'\t' read -r date spend iitm all u1 u2 u3 input output per_user fetched; do
  # One row per completed UTC date. Keep the first observed completed value;
  # later snapshots remain in logs/raw/ for checking revisions.
  if ! awk -F, -v d="$date" 'NR > 1 && $1 == d { found=1 } END { exit !found }' "$CSV"; then
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
      "$date" "$spend" "$iitm" "$all" "$u1" "$u2" "$u3" \
      "$input" "$output" "$per_user" "$fetched" >> "$CSV"
  fi
done
