import { useEffect, useMemo, useState } from "react";
import { createTodo, deleteTodo, listTodos, updateTodo } from "./api";
import RaccoonMascot from "./RaccoonMascot.jsx";

export default function App() {
  const [todos, setTodos] = useState([]);
  const [title, setTitle] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  async function refresh() {
    const items = await listTodos();
    setTodos(items);
  }

  useEffect(() => {
    refresh()
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  const remaining = useMemo(
    () => todos.filter((todo) => !todo.done).length,
    [todos],
  );

  async function onSubmit(event) {
    event.preventDefault();
    const nextTitle = title.trim();
    if (!nextTitle) {
      return;
    }
    setError("");
    try {
      const created = await createTodo(nextTitle);
      setTodos((current) => [created, ...current]);
      setTitle("");
    } catch (err) {
      setError(err.message);
    }
  }

  async function onToggle(todo) {
    setError("");
    try {
      const updated = await updateTodo(todo.id, { done: !todo.done });
      setTodos((current) =>
        current.map((item) => (item.id === todo.id ? updated : item)),
      );
    } catch (err) {
      setError(err.message);
    }
  }

  async function onDelete(id) {
    setError("");
    try {
      await deleteTodo(id);
      setTodos((current) => current.filter((item) => item.id !== id));
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div className="page">
      <div className="glow" aria-hidden="true" />
      <header className="hero">
        <RaccoonMascot mood={remaining === 0 && todos.length > 0 ? "sleepy" : "happy"} />
        <div>
          <p className="eyebrow">raccoon-herder demo den</p>
          <h1>Raccoon Stash</h1>
          <p className="tagline">
            Little paws, little tasks. Hide the good stuff in the JSON hole
            and raid it later.
          </p>
        </div>
      </header>

      <main className="panel">
        <form className="composer" onSubmit={onSubmit}>
          <label className="sr-only" htmlFor="title">
            New stash item
          </label>
          <input
            id="title"
            value={title}
            onChange={(event) => setTitle(event.target.value)}
            placeholder="What are we raiding next?"
            autoComplete="off"
          />
          <button type="submit">Stash it</button>
        </form>

        {error ? <p className="banner error">{error}</p> : null}
        {loading ? <p className="banner">Sniffing around the stash…</p> : null}

        {!loading && todos.length === 0 ? (
          <p className="empty">The stash is empty. Go forage!</p>
        ) : (
          <ul className="stash">
            {todos.map((todo) => (
              <li key={todo.id} className={todo.done ? "done" : ""}>
                <button
                  type="button"
                  className="paw"
                  onClick={() => onToggle(todo)}
                  aria-pressed={todo.done}
                  aria-label={todo.done ? "Mark as not done" : "Mark as done"}
                >
                  {todo.done ? "🐾" : "○"}
                </button>
                <span>{todo.title}</span>
                <button
                  type="button"
                  className="ghost"
                  onClick={() => onDelete(todo.id)}
                >
                  release
                </button>
              </li>
            ))}
          </ul>
        )}

        <footer className="status">
          {remaining === 0
            ? "All shiny things sorted. Time for a log nap."
            : `${remaining} treat${remaining === 1 ? "" : "s"} still in the stash`}
        </footer>
      </main>
    </div>
  );
}
