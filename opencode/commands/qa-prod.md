---
description: Boot prod-build QA lane (build, :3022, cookieless session)
---

Run the prod-build QA lane for this Next.js project from its repo root:

1. Free port 3022 (`lsof -ti :3022 | xargs -r kill`), then `TEST_MODE=true next build`. On build failure, stop and report.
2. Start the server in the background: `TEST_MODE=true next start -p 3022`.
3. Fresh cookieless browser session with a unique name (e.g. `qa-prod-$(date +%s)`, so no prior cookies/restore state apply) and a desktop viewport: `agent-browser set viewport 1440 900 --session <name>` before `agent-browser open http://localhost:3022 --session <name>` — the headless default height clips nav labels and mis-maps click points.
4. Drive the flow under test end-to-end via snapshot + interaction; watch console errors and failed network requests.
5. Report findings with exact repro steps. Then kill the 3022 server and `agent-browser close --all` unless asked to keep them running.

$ARGUMENTS
