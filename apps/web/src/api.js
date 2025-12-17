const API_BASE = import.meta.env.VITE_API_BASE || "http://localhost:8000";

export async function apiGet(path) {
  const r = await fetch(`${API_BASE}${path}`);
  if (!r.ok) throw new Error(await r.text());
  return await r.json();
}

export async function apiPost(path, body) {
  const r = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!r.ok) throw new Error(await r.text());
  return await r.json();
}

export function reportsUrl(relPath) {
  const base = API_BASE.replace(/\/$/, "");
  const rp = relPath.replace(/^reports\//, "");
  return `${base}/reports/${rp}`;
}
