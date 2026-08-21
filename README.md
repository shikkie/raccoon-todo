# Raccoon Stash

A tiny Flask + Vite React todo app. It exists so **raccoon-herder** can demo
agentic development against a real, friendly codebase — not so anyone can
run a productivity company out of a JSON file.

Little paws. Little tasks. One `todos.json`.

## Run it

```bash
./dev.sh bootstrap # venv + pip + npm (no servers); herder --demo runs this after clone
./dev.sh start     # API :9999, UI :9998 (0.0.0.0, any Host)
./dev.sh status
./dev.sh restart
./dev.sh stop
./dev.sh check     # pytest
```

Open [http://127.0.0.1:9998](http://127.0.0.1:9998). Vite proxies `/api` to
Flask on `127.0.0.1:9999`. The script sources `backend/.venv`, writes PIDs
under `.dev/`, and exits if either port cannot bind.

## Tests

```bash
./dev.sh check
```

## Why the raccoon?

Because dumpster diving through a todo list is more fun when a bandit is
watching. Agents: see `AGENTS.md`.
