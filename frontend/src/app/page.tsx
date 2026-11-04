"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";

type User = { userId: number; name: string; email: string; role: "USER" | "ADMIN" };
type Invention = {
  invention_id: number;
  title: string;
  abstract: string | null;
  description: string | null;
  category: string;
  inventors: string | null;
  patent_count: number;
  similarity?: number;
};

async function responseJson<T>(response: Response): Promise<T> {
  const body = (await response.json()) as T & { error?: string };
  if (!response.ok) throw new Error(body.error ?? "The request failed.");
  return body;
}

export default function HomePage() {
  const [user, setUser] = useState<User | null>(null);
  const [inventions, setInventions] = useState<Invention[]>([]);
  const [results, setResults] = useState<Invention[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");
  const [loginEmail, setLoginEmail] = useState("");
  const [loginPassword, setLoginPassword] = useState("");
  const [query, setQuery] = useState("");
  const [newInvention, setNewInvention] = useState({ title: "", category: "", abstract: "", description: "" });
  const [editingInvention, setEditingInvention] = useState<Invention | null>(null);

  const loadInventions = useCallback(async () => {
    const data = await responseJson<{ inventions: Invention[] }>(
      await fetch("/api/inventions", { cache: "no-store" }),
    );
    setInventions(data.inventions);
  }, []);

  const loadSession = useCallback(async () => {
    const response = await fetch("/api/auth/me", { cache: "no-store" });
    if (response.status === 401) {
      setUser(null);
      setInventions([]);
      return;
    }
    const data = await responseJson<{ user: User }>(response);
    setUser(data.user);
    await loadInventions();
  }, [loadInventions]);

  useEffect(() => {
    void loadSession()
      .catch((error: unknown) => setNotice(error instanceof Error ? error.message : "Could not load PatentPath."))
      .finally(() => setLoading(false));
  }, [loadSession]);

  async function signIn(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setNotice("");
    try {
      await responseJson(await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: loginEmail, password: loginPassword }),
      }));
      setLoginPassword("");
      await loadSession();
      setNotice("Signed in successfully.");
    } catch (error) {
      setNotice(error instanceof Error ? error.message : "Sign-in failed.");
    } finally {
      setBusy(false);
    }
  }

  async function signOut() {
    setBusy(true);
    try {
      await responseJson(await fetch("/api/auth/logout", { method: "POST" }));
      setUser(null);
      setInventions([]);
      setResults(null);
      setNotice("You have signed out.");
    } catch (error) {
      setNotice(error instanceof Error ? error.message : "Sign-out failed.");
    } finally {
      setBusy(false);
    }
  }

  async function runSearch(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setNotice("");
    try {
      const data = await responseJson<{ results: Invention[] }>(
        await fetch("/api/search", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ query }),
        }),
      );
      setResults(data.results);
      setNotice(`Found ${data.results.length} semantically related invention${data.results.length === 1 ? "" : "s"}.`);
    } catch (error) {
      setNotice(error instanceof Error ? error.message : "Search failed.");
    } finally {
      setBusy(false);
    }
  }

  async function addInvention(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setNotice("");
    try {
      const isEditing = editingInvention !== null;
      const endpoint = isEditing
        ? `/api/inventions/${editingInvention.invention_id}`
        : "/api/inventions";
      await responseJson(await fetch(endpoint, {
        method: isEditing ? "PATCH" : "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(newInvention),
      }));
      setEditingInvention(null);
      setNewInvention({ title: "", category: "", abstract: "", description: "" });
      setResults(null);
      await loadInventions();
      setNotice(isEditing ? "Invention updated and re-indexed for semantic search." : "Invention saved and indexed for semantic search.");
    } catch (error) {
      setNotice(error instanceof Error ? error.message : "The invention could not be saved.");
    } finally {
      setBusy(false);
    }
  }

  function startEditing(invention: Invention) {
    setEditingInvention(invention);
    setNewInvention({
      title: invention.title,
      category: invention.category,
      abstract: invention.abstract ?? "",
      description: invention.description ?? "",
    });
    setResults(null);
    setNotice("");
  }

  function cancelEditing() {
    setEditingInvention(null);
    setNewInvention({ title: "", category: "", abstract: "", description: "" });
  }

  async function deleteInvention(invention: Invention) {
    if (!window.confirm(`Delete "${invention.title}"? This cannot be undone.`)) return;

    setBusy(true);
    setNotice("");
    try {
      await responseJson(await fetch(`/api/inventions/${invention.invention_id}`, {
        method: "DELETE",
      }));
      if (editingInvention?.invention_id === invention.invention_id) cancelEditing();
      setResults(null);
      await loadInventions();
      setNotice(`"${invention.title}" was deleted.`);
    } catch (error) {
      setNotice(error instanceof Error ? error.message : "The invention could not be deleted.");
    } finally {
      setBusy(false);
    }
  }

  if (loading) {
    return <main className="loading-screen">Loading PatentPath…</main>;
  }

  if (!user) {
    return (
      <main className="auth-page">
        <section className="auth-card">
          <div className="brand-mark">P</div>
          <p className="eyebrow">PATENTPATH · INVENTION DISCOVERY</p>
          <h1>Find the ideas<br />connected to yours.</h1>
          <p className="muted">Search invention records by meaning, not only exact keywords.</p>
          <form onSubmit={signIn} className="form-stack">
            <label>Email<input type="email" autoComplete="username" required value={loginEmail} onChange={(event) => setLoginEmail(event.target.value)} /></label>
            <label>Password<input type="password" autoComplete="current-password" required value={loginPassword} onChange={(event) => setLoginPassword(event.target.value)} /></label>
            <button disabled={busy} className="primary-button">{busy ? "Signing in…" : "Sign in"}</button>
          </form>
          <p className="demo-hint">Local demo: aarav@example.com · PatentPathDemo123!</p>
          {notice && <p className="notice" role="status">{notice}</p>}
        </section>
      </main>
    );
  }

  const visibleInventions = results ?? inventions;

  return (
    <main className="app-shell">
      <header className="topbar">
        <a className="brand" href="#"><span className="brand-mark small">P</span><span>PatentPath</span></a>
        <div className="account">
          <span className="avatar">{user.name.slice(0, 1).toUpperCase()}</span>
          <span className="account-name">{user.name}<small>{user.role === "ADMIN" ? "Administrator" : "Researcher"}</small></span>
          <button className="text-button" onClick={signOut} disabled={busy}>Sign out</button>
        </div>
      </header>

      <section className="hero">
        <p className="eyebrow">IDEA DISCOVERY, WITH CONTEXT</p>
        <h1>Start with a question.<br /><span>Find a new direction.</span></h1>
        <p className="hero-copy">Describe the technology you are exploring. Semantic search compares its meaning with invention records and related patent information.</p>
        <form className="search-form" onSubmit={runSearch}>
          <span className="search-icon" aria-hidden="true">⌕</span>
          <input value={query} onChange={(event) => setQuery(event.target.value)} minLength={3} maxLength={1000} placeholder="e.g. low-cost sensors that detect water leaks" aria-label="Describe an invention to search for" required />
          <button disabled={busy}>{busy ? "Searching…" : "Search ideas"} <span aria-hidden="true">→</span></button>
        </form>
        <div className="search-note"><span className="status-dot" /> Semantic search · local MiniLM embeddings · Qdrant</div>
      </section>

      {notice && <p className="notice app-notice" role="status">{notice}</p>}

      <section className="results-section">
        <div className="section-heading">
          <div><p className="eyebrow">{results ? "SEARCH RESULTS" : "DISCOVER THE COLLECTION"}</p><h2>{results ? "Closest ideas" : "Invention library"} <span className="count-pill">{visibleInventions.length}</span></h2></div>
          {results && <button className="text-button" onClick={() => { setResults(null); setNotice(""); }}>Show all inventions</button>}
        </div>
        {visibleInventions.length ? (
          <div className="invention-grid">
            {visibleInventions.map((invention) => (
              <article className="invention-card" key={invention.invention_id}>
                <div className="card-meta"><span className="category-chip">{invention.category}</span>{invention.similarity !== undefined && <span className="score">{Math.round(invention.similarity * 100)}% match</span>}</div>
                <h3>{invention.title}</h3>
                <p>{invention.abstract || invention.description || "No summary has been added yet."}</p>
                <div className="card-footer"><span>{invention.inventors || "Inventor details not listed"}</span><span>{invention.patent_count} {invention.patent_count === 1 ? "patent" : "patents"}</span></div>
                {user.role === "ADMIN" && (
                  <div className="card-actions">
                    <button className="text-button" onClick={() => startEditing(invention)} disabled={busy}>
                      Edit
                    </button>
                    <button className="text-button" onClick={() => void deleteInvention(invention)} disabled={busy}>
                      Delete
                    </button>
                  </div>
                )}
              </article>
            ))}
          </div>
        ) : (
          <div className="empty-state"><span>⌕</span><h3>{results ? "No close matches yet" : "No inventions found"}</h3><p>{results ? "Try broader wording, a technical synonym, or a different description." : "Seed the database or add an invention to begin."}</p></div>
        )}
      </section>

      {user.role === "ADMIN" && (
        <section className="admin-section">
          <div className="section-heading"><div><p className="eyebrow">COLLECTION MANAGEMENT</p><h2>{editingInvention ? "Edit invention" : "Add an invention"}</h2></div><span className="admin-badge">ADMIN</span></div>
          <form className="admin-form" onSubmit={addInvention}>
            <label>Title<input required minLength={3} maxLength={200} value={newInvention.title} onChange={(event) => setNewInvention({ ...newInvention, title: event.target.value })} /></label>
            <label>Category<input required minLength={2} maxLength={100} value={newInvention.category} onChange={(event) => setNewInvention({ ...newInvention, category: event.target.value })} /></label>
            <label className="wide">Abstract<textarea maxLength={5000} rows={2} value={newInvention.abstract} onChange={(event) => setNewInvention({ ...newInvention, abstract: event.target.value })} /></label>
            <label className="wide">Description<textarea maxLength={10000} rows={3} value={newInvention.description} onChange={(event) => setNewInvention({ ...newInvention, description: event.target.value })} /></label>
            <button className="primary-button" disabled={busy}>{editingInvention ? "Save changes" : "Save and index invention"}</button>
            {editingInvention && (
              <button type="button" className="text-button" onClick={cancelEditing} disabled={busy}>
                Cancel edit
              </button>
            )}
          </form>
        </section>
      )}
      <footer className="footer"><span>PatentPath · DBMS Level 3 project</span><span>Relational data + vector similarity search</span></footer>
    </main>
  );
}
