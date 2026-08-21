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
  the sole source for Jira implementation and publication procedure.
- The workflow writes per-run branch and link values to the trusted
  `.jira-agent/publication.json` contract. The inline invocation prompt only points
  at the task; it does not duplicate the skill.
- The model invocation receives a short-lived GitHub App installation token as
  `GH_TOKEN` only so it can authenticate Git, push its assigned `ai/...` branch, and
  create the PR as the App bot.
- In the same invocation, the agent adds focused tests, runs every applicable backend
  and/or frontend check, fixes failures, reruns affected checks, and reports results.
- There is no separate verification action and no repair/resume model invocation.
- A trusted pre-push hook rejects empty, unsafe, oversized, symlink, and protected-path
  patches before the agent can publish them.

### Publication or failure

- The agent creates `ai/<issue>-<run>`, commits, pushes, and opens a normal PR in its
  implementation invocation. It uses the same concise, 72-character action line for
  the commit subject and PR title and a short three-section PR body.
- The workflow records the reported repository PR URL, adds a visible job summary,
  and posts the publication links to Jira.
- Failures remain visible in the Actions logs and update Jira when possible.

## 3. Pull-request CI — `build.yml`

- Every generated PR runs the normal Build workflow unchanged.
- Required checks include backend RSpec, RuboCop, Brakeman, frontend production build,
  dependency review, secret scanning, and SonarQube.
- CI reports its checks without modifying the PR branch.

## 4. Requested-changes revisions — `jira-agent-review.yml`

- A submitted **Request changes** review on an open App-authored `ai/...` pull request
  enters a read-only admission stage first.
- The admission stage verifies the reviewer has repository write access, the PR is
  current and targets `main`, and the review has a summary or inline feedback. Review
  text is sanitized as untrusted data.
- A successful revision run makes exactly one non-force-pushed App-authored commit on
  the existing branch. It never creates a second pull request.
- The existing Build workflow runs again from the resulting `synchronize` event.

## Human control and trust boundaries

- After CI, the PR remains unchanged for human review and merge.
- The coding agent receives a repository-scoped GitHub App installation token and may
  push only its assigned branch and create its PR. Repository instructions still
  forbid approval, merge, auto-merge, deletion, and pushes to `main`.
- Bedrock uses short-lived OIDC access; OpenRouter uses only its step-scoped API key.
- Jira and test content is always treated as untrusted data.
