# Raccoon Stash

Tiny example todo app used in **raccoon-herder** agentic-development demos.
Keep it simple, cute, and easy for agents to change in a short session.

## What this is

- Backend: Python Flask on **127.0.0.1:9999**
- Frontend: Vite + React (JavaScript, not TypeScript) on **0.0.0.0:9998** (any Host header)
- Runner: `./dev.sh` start/stop/restart/status (venv, PIDs, bind-or-fail)
- Persistence: one JSON file, not a real database
- Theme: woodland raccoon / trash-panda den. Fun copy is encouraged.

Do not "improve" this into a serious production app unless a human asks.
No auth, no SQL, no ORMs, no CSS frameworks, no TypeScript conversion.

## Layout

```
backend/app.py            Flask factory + /api routes
backend/store.py          JSON file read/write
backend/data/todos.json   the "database"
backend/tests/            pytest, Flask test client
frontend/src/App.jsx      UI
frontend/src/api.js       fetch wrappers; always call /api/...
frontend/vite.config.js   proxies /api -> http://127.0.0.1:9999
dev.sh                    start/stop/restart with PID files in .dev/
```

## Commands

From the repo root:

```bash
# usual path — sources the venv, tracks PIDs, fails if ports cannot bind
./dev.sh start
./dev.sh status
./dev.sh restart
./dev.sh stop
./dev.sh check          # pytest; extra args are passed through
```

The Vite dev server proxies `/api` to Flask on port 9999. Browser code must
use relative `/api/...` URLs. Never hardcode localhost ports in the frontend.
`./dev.sh` must fail cleanly if 9998 or 9999 cannot be bound; do not let Vite
pick another port (`strictPort`).

Override the JSON file with `RACCOON_TODO_DB=/path/to/file.json` when testing.

## API

| Method | Path | Body | Result |
| --- | --- | --- | --- |
| GET | `/api/health` | | `{ ok, app }` |
| GET | `/api/todos` | | array of todos |
| POST | `/api/todos` | `{ "title": string }` | 201 todo |
| PATCH | `/api/todos/<id>` | `{ "title"?, "done"? }` | todo |
| DELETE | `/api/todos/<id>` | | 204 |

A todo is `{ id, title, done, created_at }`. Trim titles. Reject blanks with 400.
Unknown ids are 404.

## Agent rules

- Change the smallest surface that satisfies the request.
- Keep raccoon flavor in UI copy and empty states.
- New API fields belong in `store.py` **and** the JSON documents.
- Add or update a pytest when you touch API behavior.
- Frontend: functional components, `fetch` via `src/api.js`, plain CSS in `index.css`.
- Do not add React Router, Redux, Tailwind, or a component library.
- Do not commit `node_modules/`, `.venv/`, or `__pycache__/`.
- Prefer one JSON file over introducing SQLite/Postgres/"just for now" databases.

## Demo-friendly next tasks

These are good raccoon-herder exercises because they stay small:

- Add due dates or "shininess" priority
- Filter active vs. stashed-away (completed)
- Inline rename of a todo
- A second raccoon mood when the list is empty
- Export/download the stash JSON
