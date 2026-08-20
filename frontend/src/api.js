async function request(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });

  if (response.status === 204) {
    return null;
  }

  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(payload.error || `Request failed (${response.status})`);
  }
  return payload;
}

export function listTodos() {
  return request("/api/todos");
}

export function createTodo(title) {
  return request("/api/todos", {
    method: "POST",
    body: JSON.stringify({ title }),
  });
}

export function updateTodo(id, patch) {
  return request(`/api/todos/${id}`, {
    method: "PATCH",
    body: JSON.stringify(patch),
  });
}

export function deleteTodo(id) {
  return request(`/api/todos/${id}`, { method: "DELETE" });
}
