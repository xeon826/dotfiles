When a project's rules change, update its AGENTS.md — extend existing sections where possible, prune what becomes stale, and don't append narration of routine code changes (commit messages cover that).

Never `git commit` or `git push` on your own initiative — in any repo, including when a project's workflow (CI-on-merge, PR flow) makes it convenient. Prepare the changes, leave the branch/working tree ready, and tell the user it's ready; only commit or push when they explicitly ask in that request. Project conventions about commit style apply only once the user has asked for the commit.

## DRY — "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system" (Hunt & Thomas, The Pragmatic Programmer)

Apply DRY broadly — not just code (dedupe via functions/abstractions) but database schemas, test plans, build systems, and documentation too. Prefer abstractions that are unlikely to change, or normalize data so redundancy never exists. Done right, changing one element never requires touching logically unrelated elements, and related elements change predictably and stay in sync. When you find yourself copy-pasting knowledge across files, extract it to its single authoritative source instead.

Try to refrain from using insider lingo when talking about finances.

The `google-ads` MCP server runs via `uvx google-ads-mcp` (Google's official package). Its credential is a dedicated authorized-user ADC file at `~/.config/google-ads/user-adc.json`, minted from the OAuth desktop client in the `dan-marketing-mcp-01` Google Cloud project. Developer tokens were sunset in September 2026 — API access level (currently Test; Explorer application pending) is tied to that project, and querying production accounts additionally requires the account to allow it. Access through a manager account needs `GOOGLE_ADS_LOGIN_CUSTOMER_ID` set in the MCP entry's environment.
