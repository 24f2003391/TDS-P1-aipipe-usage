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

# Initialise the expanded schema if this is a new repository.
if [ ! -f "$CSV" ]; then
  echo "$HEADER" > "$CSV"
fi

# Only archive complete, available days. The provider-count buckets are
# all-domain distinct users; their sum is the all-domain user count.
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
      (if $all > 0 then (($d.total.spend_usd / $all) * 100000000 | round) / 100000000 else 0 end),
      $ts
    ] | @csv
' "$RAW" | while IFS= read -r row; do
  day="${row%%,*}"
  # Each date is archived once. Keep the original fetch timestamp for
  # provenance; raw snapshots preserve subsequent feed revisions.
  if ! awk -F, -v d="$day" 'NR > 1 && $1 == d { found=1 } END { exit !found }' "$CSV"; then
    echo "$row" >> "$CSV"
  fi
done
