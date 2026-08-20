"""Raccoon Stash API — Flask + a JSON file pretending to be a database."""

from __future__ import annotations

import os
from pathlib import Path

from flask import Flask, jsonify, request

from store import DEFAULT_DATA_PATH, TodoStore


def create_app(data_path: Path | str | None = None) -> Flask:
    app = Flask(__name__)
    path = data_path or os.environ.get("RACCOON_TODO_DB") or DEFAULT_DATA_PATH
    store = TodoStore(path)

    @app.get("/api/health")
    def health():
        return jsonify({"ok": True, "app": "raccoon-stash"})

    @app.get("/api/todos")
    def list_todos():
        return jsonify(store.list())

    @app.post("/api/todos")
    def create_todo():
        body = request.get_json(silent=True) or {}
        title = (body.get("title") or "").strip()
        if not title:
            return jsonify({"error": "title is required"}), 400
        return jsonify(store.create(title)), 201

    @app.patch("/api/todos/<todo_id>")
    def update_todo(todo_id: str):
        body = request.get_json(silent=True) or {}
        title = body.get("title")
        done = body.get("done")

        if title is not None:
            title = title.strip()
            if not title:
                return jsonify({"error": "title is required"}), 400
        if done is not None and not isinstance(done, bool):
            return jsonify({"error": "done must be a boolean"}), 400
        if title is None and done is None:
            return jsonify({"error": "nothing to update"}), 400

        todo = store.update(todo_id, title=title, done=done)
        if todo is None:
            return jsonify({"error": "not found"}), 404
        return jsonify(todo)

    @app.delete("/api/todos/<todo_id>")
    def delete_todo(todo_id: str):
        if not store.delete(todo_id):
            return jsonify({"error": "not found"}), 404
        return ("", 204)

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=9999, debug=True)
