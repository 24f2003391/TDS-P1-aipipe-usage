# AI Pipe public usage observations

This repository archives the public [AI Pipe usage feed](https://stats.aipipe.org/usage.json) for longitudinal analysis. It does **not** have access to private per-user usage records.

## Data files

- `logs/raw/usage-<timestamp>.json`: unmodified snapshots named by UTC fetch time.
- `logs/daily.csv`: one row per completed UTC day, with all-domain user counts and provider-level aggregates.
- `.github/workflows/log-usage.yml`: scheduled GitHub Actions collection.
- `scripts/log_usage.sh`: fetches and archives the public feed.

The workflow runs every six hours at minute 15 UTC. The feed itself is published on a six-hour schedule. Raw snapshots matter because a later snapshot can revise a day's figures or show a different rolling window.

## CSV columns

| Column | Meaning |
|---|---|
| `date` | Feed date in UTC. |
| `spend_usd` | Total positive-cost tracked spend across all included email domains. **Not IITM-only spend.** |
| `iitm_users` | Distinct users matching the feed's IITM email-domain filter with counted positive-cost usage that day. |
| `all_domain_users` | Sum of provider-count buckets `1`, `2`, and `3+`: distinct users across all domains with counted usage. |
| `users_1_provider`, `users_2_providers`, `users_3plus_providers` | All-domain users grouped by number of providers used that UTC day. These are people counts, not request counts. Their sum should equal `all_domain_users`. |
| `input_tokens`, `output_tokens` | Total reported input/output tokens across included users and providers. Missing token counts may be zero. |
| `spend_per_all_domain_user_usd` | `spend_usd / all_domain_users`; a rough average across counted all-domain users, not an IITM-specific average. `NA` when there are no users. |
| `openai_spend_usd`, `gemini_spend_usd` | Spend attributed to each provider in the public feed. |
| `other_provider_spend_usd` | Total spend minus OpenAI and Gemini spend, preserving visibility if another provider appears. |
| `openai_input_tokens`, `openai_output_tokens`, `gemini_input_tokens`, `gemini_output_tokens` | Provider-level token totals as reported by the feed. |
| `other_provider_input_tokens`, `other_provider_output_tokens` | Total tokens minus OpenAI and Gemini token totals. |
| `fetched_at` | UTC timestamp of the first snapshot in which this completed date was archived, formatted as `YYYYMMDDTHHMMSSZ`. |

## Inclusion and interpretation limits

The [AI Pipe repository](https://github.com/sanand0/aipipe) and public-feed documentation describe a **metered-usage subset**, not every AI Pipe interaction:

- Positive-cost requests are included.
- Free/zero-cost requests and requests that bypass AI Pipe metering (such as direct native provider API keys) are not represented in these aggregates.
- Spend can be counted even when token details are unavailable; missing token counts may be zero.
- The feed separates an IITM-domain user count from total spend and all-domain user counts. Do not label total spend as IITM-only or divide it by `iitm_users` and call the result average IITM spending.
- The IITM count follows the implementation's email matching rule; it may not cover every possible IITM-associated address.
- The feed is a rolling window and the current day is incomplete. Raw snapshots preserve what was visible before old dates roll out of the public window.
- The logger records each completed date once in the CSV. If the source revises a completed date later, compare raw snapshots rather than assuming the CSV is the final immutable truth.
- Aggregate correlation cannot identify who generated usage or why. Assignment deadlines can be considered a hypothesis, not a proven cause.

## Observation: 2026-10-22

In the snapshot fetched at `20261023T044324Z`, the completed 2026-10-22 row reported:

- Total tracked spend: **$11.00722815**
- Input tokens: **21,308,082**
- Output tokens: **1,885,061**
- IITM-filtered users: **70**
- All-domain counted users: **76** (76 used one provider; zero used two or three-plus)
- OpenAI spend: **$11.00722815**; Gemini spend: **$0**

The $11.01 total is across all included domains. The public feed does not break out spend specifically attributable to the 70 IITM-filtered users. This spike alone cannot establish a cause.


## Dashboard

The repository includes a static, public analytics dashboard at the repository root:

- `index.html`: responsive AI Pipe Analytics Terminal.
- `.github/workflows/deploy-pages.yml`: builds a small Pages artifact containing the dashboard and `logs/daily.csv`, then deploys it to GitHub Pages.
- The dashboard reads `./logs/daily.csv` at runtime. It does not require a server, database, API key, or private usage access.

### Publish with GitHub Pages

1. Open **Settings → Pages** in this repository.
2. Under **Build and deployment → Source**, select **GitHub Actions**.
3. Open **Actions → Deploy AI Pipe Analytics Terminal** and run the workflow once with **Run workflow**, or push a change to `index.html`.
4. After the deployment job succeeds, the site is available at:

   https://24f2003391.github.io/TDS-P1-aipipe-usage/

The deploy workflow also runs when `logs/daily.csv` changes, so new completed daily records are published after the existing collection workflow commits them. The existing six-hour collection workflow is unchanged.

### Dashboard interpretation

- Spend and provider totals are all-domain public-feed aggregates, not IITM-only spend.
- IITM-filtered users and all-domain counted users are shown as separate measures.
- User figures are daily distinct-user counts, not request counts.
- Charts use completed daily records only; the latest partial day is excluded by the collector.
- The dashboard's CSV export contains the filtered historical rows.
- The browser loads Chart.js from jsDelivr for charts. The underlying CSV remains available directly in the repository.
