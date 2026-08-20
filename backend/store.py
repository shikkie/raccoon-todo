"""Tiny JSON-file todo store. One process, one lock, no real database."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from threading import Lock
from uuid import uuid4

DEFAULT_DATA_PATH = Path(__file__).resolve().parent / "data" / "todos.json"


class TodoStore:
    def __init__(self, path: Path | str | None = None) -> None:
        self.path = Path(path) if path else DEFAULT_DATA_PATH
        self._lock = Lock()
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self._write({"todos": []})

    def list(self) -> list[dict]:
        with self._lock:
            return list(self._read()["todos"])

    def create(self, title: str) -> dict:
        todo = {
            "id": str(uuid4()),
            "title": title,
            "done": False,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        with self._lock:
            data = self._read()
            data["todos"].insert(0, todo)
            self._write(data)
        return todo

    def update(self, todo_id: str, *, title: str | None = None, done: bool | None = None) -> dict | None:
        with self._lock:
            data = self._read()
            for todo in data["todos"]:
                if todo["id"] == todo_id:
                    if title is not None:
                        todo["title"] = title
                    if done is not None:
                        todo["done"] = done
                    self._write(data)
                    return dict(todo)
        return None

    def delete(self, todo_id: str) -> bool:
        with self._lock:
            data = self._read()
            remaining = [todo for todo in data["todos"] if todo["id"] != todo_id]
            if len(remaining) == len(data["todos"]):
                return False
            data["todos"] = remaining
            self._write(data)
            return True

    def _read(self) -> dict:
        with self.path.open(encoding="utf-8") as handle:
            payload = json.load(handle)
        todos = payload.get("todos")
        if not isinstance(todos, list):
            return {"todos": []}
        return {"todos": todos}

    def _write(self, data: dict) -> None:
        tmp = self.path.with_suffix(".json.tmp")
        with tmp.open("w", encoding="utf-8") as handle:
            json.dump(data, handle, indent=2)
            handle.write("\n")
        tmp.replace(self.path)
