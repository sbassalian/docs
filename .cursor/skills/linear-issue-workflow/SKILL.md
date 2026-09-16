---
name: linear-issue-workflow
description: Workflow for ALL engineering work in the Growi repos — every code change gets a Linear issue FIRST, the issue moves In Progress → In Review → Done, and commits reference the ENG identifier. Also used by Cursor Cloud on tech@growi.io. Use whenever the user or a Slack/Linear ticket asks for a fix, feature, or change.
---

# Linear issue workflow

This skill is the source of truth for Cursor (desktop and Cloud on `tech@growi.io`). Do not invent a second lifecycle.

## Ask vs Fix (mandatory on Cloud / assign-to-Cursor)

Every CS Slack question is ticketed and assigned to **Cursor**. Grok Bot never answers from its own confidence. There is no “80% sure, send now” path.

Decide Ask vs Fix from the Linear title, description, and attached Slack thread.

**Ask (account manager):** how-to, where-is-the-setting, timezone, “what does this mean,” “can Growi tell if…,” policy.

1. Search the repos (and only the ticket’s org/creator if you have read-only data).
2. Comment a customer-ready reply on the Linear issue plus file/line proof.
3. **Dashboard Juno check (required on every Ask).** Can the in-dashboard assistant already answer this for the brand?
   - Look at `app/services/assistant/system_prompt.rb` playbooks, `Mcp::Toolbox` tools, and the dash UI the brand would use.
   - **Yes:** say so on Linear (tool name / playbook / drawer path). No extra PR unless that playbook is stale.
   - **No:** this Ask is also a Fix. Add the missing playbook, MCP tool, and/or self-serve dash path so the next brand can ask Juno instead of Slack. Never mutate production data.
4. Move the issue to **In Review** (or Done if FAQ-only and Juno already covers it with no code to ship).
5. Never send Slack as Solomon. Ben sends only after this Linear comment exists. Ben still does not send money / legal / churn / angry — those stay human.

**Fix (engineer):** bug, missing feature, “update my campaign / settings,” dash cannot do it today.

1. Follow the full lifecycle below.
2. If the customer asked to change settings the dash/Juno cannot do, the PR adds that self-serve path. Never mutate production data.
3. If the change would change what Juno tells a brand, update `system_prompt.rb` / tools in the same PR (see `.cursor/rules/juno-answers-stay-current.mdc`).
4. Open a PR, post QA proof on Linear, move to **In Review**, ping Solomon to approve.
5. Merge **only** after Solomon approves on Slack or the GitHub PR. Then stop. Solomon deploys. Ben follow-up is after deploy.

If unsure, treat it as **Ask** first, still run the Juno check, and say what a Fix PR would be.

## Issue-first rule (mandatory)

Never start code changes without a Linear issue.

1. **Before writing any code:** use the referenced issue, or CREATE one (see below) and move it to **In Progress**.
2. **Reference the identifier** (e.g. `ENG-10731`) in every commit and PR across every repo the change touches.
3. **Narrate on the issue:** started (In Progress), PR + QA proof (In Review), merged after approve (still In Review until Solomon deploys), shipped (Done).
4. **Retroactive is better than never:** if work finished without an issue, create it in Done with commit hashes.

## Autonomous / Cloud Agent runs

When running as Cursor Cloud (or any agent not on Solomon’s laptop):

- Work in the **clean clone** Cloud provides. Never assume `/Users/solomonbassalian/Documents/growi` exists.
- Do **not** copy or read laptop `.env` files. No prod writes. No POST/PUT/PATCH/DELETE to production APIs. A read-only replica may exist later; until then, answer from code.
- Use the issue’s `gitBranchName` when creating the branch.
- Never push straight to `main`.
- **Merge only after Solomon approves** on Slack (`#cs-agent-review` or the ticket thread) or by approving the GitHub PR. If there is no explicit approve, leave the PR open.
- Ping Solomon on the Linear issue with the PR URL and the draft customer follow-up.

When the prompt says you are in dispatcher worktrees under `~/agent-work/<ISSUE>/` (legacy laptop farm):

- Work ONLY inside those worktrees. Never `cd` into `~/Documents/growi/`.
- The branch is already checked out. If there are uncommitted changes, continue from them.
- Same merge rule: approve first, never merge on your own.

## Comment-driven follow-ups

When the prompt is a new Linear comment on a ticket you already worked:

1. Move the issue back to **In Progress**.
2. Stay on the same branch and PR.
3. Address the feedback, re-verify, re-capture QA proof if UI changed.
4. Comment what changed.
5. Move back to **In Review**. Merge only if Solomon newly approved.

If the comment **is** Solomon’s approve (“lgtm”, “merge”, “approved”), merge the PR, comment the merge SHA, and leave deploy to Solomon.

## When handed an existing issue

1. Fetch the issue (`get_issue`). Read title, description, Slack attachments, `gitBranchName`.
2. Classify Ask vs Fix. Always run the dashboard Juno check. If Ask and Juno already covers it, stop after the customer-ready comment. If Ask and Juno cannot, continue as a Fix for the Juno/self-serve gap.
3. Move to **In Progress** as soon as Fix work starts.
4. Implement in the relevant repo. Verify (typecheck/lint/tests the repo provides).
5. Create a pull request:
   - Branch = issue `gitBranchName` (e.g. `tech/eng-10731-…`).
   - Commit **only** files for this issue. Pathspec commit. Never sweep unrelated index files.
   - Match `git log --oneline -5` style.
   - `gh pr create` with the issue title, identifier, and Linear URL.
6. **QA proof on the issue** for UI Fixes: screenshot or recording inline in a Linear comment (`![description](assetUrl)`). One sentence of what you verified.
7. Move to **In Review**. Ping Solomon to approve. Do not merge yet.

## Visual verification (screenshots / recordings)

Required for UI Fixes, not optional:

- Local OTP is bypassed: sign in as any org member email, any OTP code. If 403, find a member via replica `psql` (never print the URL).
- Playwright one-off (`npx playwright`) against the local URL. Cloud Agents: if you cannot run the app, say so and post code-level proof instead of faking a screenshot.
- Dark mode: if the page supports it, capture light and dark.

## Creating Linear issues

- **Team:** Engineering
- **Project:** Benji (`https://linear.app/growi/project/benji-f9ab3611ebb0`) — CS folder. Not the Cloud start trigger. Do not put normal feature work here.
- **Cycle:** current
- **Assignee:** **Cursor** (this starts Cloud). Assigning Juno alone does not start Cloud.
- **Priority:** Urgent
- **Estimate:** 1 trivial, 2 typical
- **Labels:** existing only — never create labels
- **State:** Done if logging already-shipped work, with commit hashes
- Attach the Slack thread URL.

## Notes

- Repos: `backend`, `growi-web-monorepo`, `docs`, plus shopify / gateways when the ticket needs them. Page URLs usually map to `growi-web-monorepo/apps/web` or `apps/workflows`.
- **Microfrontends:** check `apps/web/microfrontends.json` before editing. Workflows-owned routes in `apps/web` are dead. Local proxy port 3024; `/auth/signin` is workflows.
- Follow existing patterns. Do not invent a second one.
- **`user_contents` is deprecated.** Use social posts: PG `social_post_attributions`, ClickHouse `social_post_feed` / snapshots, `SocialPosts::Queries::QueryService`. Prefer `social_post_id` on tag assignments. Do not build on `UserContent`.

## Email templates

When editing `app/views/**/*_mailer/*.erb`, match the OTP verify email: light-only color-scheme meta, `#f4f4f5` outer, white 12px card, Growi wordmark, DM Sans, `#191919` / `#3f3f46` / `#71717a`. Restyle legacy Helvetica templates. QA light and dark.

## Production logs (SolarWinds / “Papertrail”)

Local laptop only: token is `PAPERTRAIL` in `backend/.env` (never print it). SWO API `https://api.na-01.cloud.solarwinds.com/v1/logs`. Cloud Agents: skip unless a read-only secret is in the Cloud environment.

- Replica analytics (laptop only, later Cloud): read-only Postgres replica. Always `_REPLICA`. Never write. Never print the URL. Never use `heroku` — production is AWS/EKS.
