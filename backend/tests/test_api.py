from pathlib import Path

import pytest

from app import create_app


@pytest.fixture
def client(tmp_path: Path):
    db = tmp_path / "todos.json"
    db.write_text('{"todos": []}\n', encoding="utf-8")
    app = create_app(db)
    app.config["TESTING"] = True
    return app.test_client()


def test_health(client):
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.get_json()["ok"] is True


def test_create_list_toggle_and_delete(client):
    created = client.post("/api/todos", json={"title": "  stash acorns  "})
    assert created.status_code == 201
    todo = created.get_json()
    assert todo["title"] == "stash acorns"
    assert todo["done"] is False

    listed = client.get("/api/todos")
    assert listed.status_code == 200
    assert len(listed.get_json()) == 1

    patched = client.patch(f"/api/todos/{todo['id']}", json={"done": True})
    assert patched.status_code == 200
    assert patched.get_json()["done"] is True

    deleted = client.delete(f"/api/todos/{todo['id']}")
    assert deleted.status_code == 204
    assert client.get("/api/todos").get_json() == []


def test_create_rejects_blank_title(client):
    response = client.post("/api/todos", json={"title": "   "})
    assert response.status_code == 400


def test_missing_todo_is_404(client):
    assert client.patch("/api/todos/nope", json={"done": True}).status_code == 404
    assert client.delete("/api/todos/nope").status_code == 404
