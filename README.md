# Mini Jira

Mini Jira is split into two applications:

- `backend/`: Rails JSON API with SQLite and session-backed user switching.
- `frontend/`: Vue 3 single-page application powered by Vite.

## Run locally

Start the Rails API:

```sh
cd backend
bundle install
bin/rails db:prepare
bin/rails server -p 3000
```

In a second terminal, start Vue:

```sh
cd frontend
npm install
npm run dev
```

Open http://localhost:5173. Vite proxies `/projects`, `/users`, and `/up` to Rails at port 3000. For a deployed frontend, set `VITE_API_URL` to the backend URL and set `FRONTEND_ORIGIN` in Rails to the frontend origin.

## Checks

```sh
cd backend && bundle exec rspec spec/models spec/requests
cd frontend && npm run build
```

## Jira-to-PR agent

The repository includes an opt-in Jira assignment pipeline with a configurable
coding agent (`claude-code` or `codex`) and model provider (`bedrock` or
`openrouter`). Jira dispatches only the issue key and an idempotency event ID;
GitHub re-fetches and sanitizes the issue before any model is invoked. Generated
changes receive agent-run local checks, agent-owned PR publication, trusted
pre-push patch validation, and normal pull-request CI, then remain for human review.
Automation never approves, merges, or pushes to `main`.

See [the workflow overview](docs/jira-agent-workflow-overview.md) for the end-to-end
flow, and [the deployment guide](docs/jira-agent-deployment.md) for Jira, GitHub, AWS
OIDC, branch-protection, and bot-token setup.
