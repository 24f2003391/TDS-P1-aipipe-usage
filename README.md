# AI Pipe public usage observations

This repository archives the public [AI Pipe usage feed](https://stats.aipipe.org/usage.json) for longitudinal analysis. It does **not** have access to private per-user usage records.

## Data files

- `logs/raw/usage-<timestamp>.json`: unmodified snapshots of the public feed, named by the UTC time they were fetched.
- `logs/daily.csv`: one row per completed UTC day, with all-domain user counts and a correctly labelled per-user aggregate.
- `.github/workflows/log-usage.yml`: scheduled GitHub Actions collection.
- `scripts/log_usage.sh`: fetches and archives the public feed.

The workflow runs every six hours at minute 15 (UTC). The feed itself is published on a six-hour schedule. The raw snapshots are important because a later snapshot can revise the current day's figures or show a different rolling window.

## Column definitions

| Column | Meaning |
|---|---|
| `date` | Feed date in UTC. |
| `spend_usd` | Total positive-cost tracked spend across all included email domains. This is **not IITM-only spend**. |
| `iitm_users` | Distinct users matching the feed's IITM email-domain filter who had counted positive-cost usage that day. |
| `all_domain_users` | Sum of `users_by_provider_count` buckets `1`, `2`, and `3+`; distinct users across all domains with counted usage. |
| `users_1_provider`, `users_2_providers`, `users_3plus_providers` | All-domain users grouped by how many providers they used that UTC day. These are people counts, not request counts. |
| `input_tokens`, `output_tokens` | Total tokens reported for counted usage across all included users/providers. Missing token counts may be zero. |
| `spend_per_all_domain_user_usd` | `spend_usd / all_domain_users`. This is a rough average across counted all-domain users, not an IITM-specific average. It is undefined when the user count is zero. |
| `fetched_at` | UTC timestamp of the first snapshot in which this completed date was archived, in compact `YYYYMMDDTHHMMSSZ` form. |

## Inclusion and interpretation limits

The repository's [AI Pipe source code](https://github.com/sanand0/aipipe) and public-feed documentation describe a **metered-usage subset**, not every AI Pipe interaction:

- Positive-cost requests are included.
- Zero-cost/free-model requests and requests that bypass AI Pipe metering (for example, direct native provider API keys) are not represented in these aggregates.
- If usage-token details are unavailable, spend can still be included while token counts are zero.
- The feed separates an IITM-domain user count from total spend and all-domain user counts. Never label total spend as IITM-only or divide it by `iitm_users` and call the result average IITM spending.
- The IITM count follows the implementation's email matching rule; it should not be assumed to cover every possible IITM-associated address.
- The feed is a rolling window and the current day is incomplete. Keep raw snapshots to preserve the historical observations as the public window advances.
- Aggregate correlation cannot identify who generated the usage or why. Assignment deadlines may be discussed as a hypothesis, not treated as a proven cause.

## Initial observation: 2026-10-22

In the snapshot fetched at `20261023T044324Z`, the completed 2026-10-22 row reported:

- Total tracked spend: **$11.00722815**
- Input tokens: **21,308,082**
- Output tokens: **1,885,061**
- IITM-filtered users: **70**
- All-domain counted users: **76** (76 used one provider; zero used two or three-plus)

The $11.01 total is across all included domains. The public feed does not provide a breakdown of spend specifically attributable to the 70 IITM-filtered users. This spike alone cannot establish a cause.

## Collection notes

The logger archives a completed date once in `daily.csv`, preserving its first observed completion timestamp. Later snapshots remain in `logs/raw/` for auditability. If a day's published values are revised after it has been archived, compare the raw snapshots; do not silently overwrite historical observations.
