# Jira agent workflow overview

An explicitly assigned Jira ticket can become a normal pull request. The selected
agent implements the change and runs its applicable checks in one invocation;
automation never approves, merges, or bypasses `main` protection.

## 1. Deployment validation — `validate-jira-agent.yml`

- Run manually before enabling Jira Automation.
- Validate the configured coding-agent/provider pair and invoke its model without
  granting repository write access.
- Do not enable the agent if validation fails.

## 2. Ticket implementation — `jira-agent.yml`

### Admission

- Jira sends only an issue key and idempotency event ID after assignment to the AI account.
- The workflow queues work, checks out recorded `main`, re-fetches and sanitizes Jira,
  verifies the assignee, and stops duplicate `ai/...` PRs.

### Implementation and agent-run verification

- The `CODING_AGENT` and `MODEL_PROVIDER` variables select Claude Code or Codex
  with Bedrock or OpenRouter; Jira cannot override the deployment choice.
- `AGENTS.md` is the shared instruction source. Claude imports it through the thin
  `CLAUDE.md` compatibility file, while Codex reads it natively. Both agents then
  read the single protected Jira implementation skill referenced there; the skill is
  not duplicated into the sanitized task artifact.
- The model invocation does not receive publishing credentials.
- In the same invocation, the agent adds focused tests, runs every applicable backend
  and/or frontend check, fixes failures, reruns affected checks, and reports results.
- There is no separate verification action and no repair/resume model invocation.
- The trusted validator rejects empty, unsafe, oversized, symlink, and protected-path
  patches before publication; it does not rerun tests.

### Publication or failure

- Only a patch accepted by the trusted publication policy reaches publisher steps.
- The bot creates `ai/<issue>-<run>`, opens a normal PR, and posts Jira links.
- Failures retain evidence, update Jira when possible, and do not intentionally create a PR.

## 3. Pull-request CI — `build.yml`

- Every generated PR runs the normal Build workflow unchanged.
- Required checks include backend RSpec, RuboCop, Brakeman, frontend production build,
  dependency review, secret scanning, and SonarQube.
- CI reports its checks without modifying the PR branch.

## Human control and trust boundaries

- After CI, the PR remains unchanged for human review and merge.
- The coding agent never directly receives the PR bot token and cannot push or merge.
- Bedrock uses short-lived OIDC access; OpenRouter uses only its step-scoped API key.
- Jira and test content is always treated as untrusted data.
