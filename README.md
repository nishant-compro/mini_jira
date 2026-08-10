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
