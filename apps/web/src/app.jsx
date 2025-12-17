import React, { useEffect, useMemo, useState } from "react";
import { apiGet, apiPost, reportsUrl } from "./api.js";
import { playMidiFromUrl } from "./midi_player.js";

function fmt(dt) {
  try { return new Date(dt).toLocaleString(); } catch { return dt; }
}

export default function App() {
  const [runs, setRuns] = useState([]);
  const [selectedId, setSelectedId] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [playInfo, setPlayInfo] = useState(null);
  const [bestFiles, setBestFiles] = useState([]);

  async function refresh() {
    setError("");
    const data = await apiGet("/api/runs");
    setRuns(data);
    if (data.length) setSelectedId(data[0].id);
  }

  useEffect(() => { refresh().catch(e => setError(String(e))); }, []);

  const selected = useMemo(() => runs.find(r => r.id === selectedId), [runs, selectedId]);

  async function importDefault() {
    setLoading(true);
    setError("");
    try {
      await apiPost("/api/runs/import", {
        name: "run_import",
        scoring_json: "reports/metrics/scoring.json",
        midi_dir: "reports/samples/midi_batch",
        figures_dir: "reports/figures",
        best_of_dir: "reports/samples/best_of",
        top: 3
      });
      await refresh();
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }

  async function generateAndImport() {
    setLoading(true);
    setError("");
    try {
      // defaults call pipeline2 + import scoring2/midi_batch2/figures/run2/best_of_run2
      await apiPost("/api/generate", {});
      await refresh();
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!selected) return;
    apiGet(`/api/runs/${selected.id}/files?kind=best_of`)
      .then(setBestFiles)
      .catch(e => setError(String(e)));
  }, [selectedId]);

  async function play(file) {
    setError("");
    setPlayInfo(null);
    try {
      const url = reportsUrl(file.rel_path);
      const info = await playMidiFromUrl(url);
      setPlayInfo({ file: file.name, ...info });
    } catch (e) {
      setError("Play MIDI échoué (navigateur): " + String(e));
    }
  }

  return (
    <div className="container">
      <div className="row" style={{ alignItems: "center", justifyContent: "space-between" }}>
        <h1 className="h1">MuseGAN TP — Front + Back</h1>
        <div className="row">
          <button className="btn secondary" onClick={() => refresh()} disabled={loading}>Rafraîchir</button>
          <button className="btn secondary" onClick={() => importDefault()} disabled={loading}>Importer (pipeline)</button>
          <button className="btn" onClick={() => generateAndImport()} disabled={loading}>Générer + importer</button>
        </div>
      </div>

      {error && <div className="card" style={{ borderColor: "#ff4d4d" }}>{error}</div>}

      <div className="row">
        <div className="card" style={{ flex: "1 1 320px" }}>
          <div className="h2">Runs</div>
          <table className="table">
            <thead><tr><th>ID</th><th>Date</th><th>Nom</th></tr></thead>
            <tbody>
              {runs.map(r => (
                <tr key={r.id} style={{ cursor: "pointer", opacity: r.id === selectedId ? 1 : 0.8 }}
                    onClick={() => setSelectedId(r.id)}>
                  <td>{r.id}</td>
                  <td className="small">{fmt(r.created_at)}</td>
                  <td>{r.name}</td>
                </tr>
              ))}
              {!runs.length && (
                <tr><td colSpan="3" className="small">Aucun run. Cliquez “Importer” ou “Générer + importer”.</td></tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="card" style={{ flex: "2 1 560px" }}>
          <div className="h2">Détails</div>
          {!selected && <div className="small">Sélectionnez un run.</div>}
          {selected && (
            <>
              <div className="kpi" style={{ marginTop: 10 }}>
                <div className="item">
                  <div className="small">Samples</div>
                  <div>{selected.summary?.stats?.n_samples ?? "-"}</div>
                </div>
                <div className="item">
                  <div className="small">Avg notes/sec</div>
                  <div>{selected.summary?.stats?.avg_notes_per_sec ?? "-"}</div>
                </div>
                <div className="item">
                  <div className="small">Max score</div>
                  <div>{selected.summary?.stats?.max_score ?? "-"}</div>
                </div>
              </div>

              <div className="row" style={{ marginTop: 12 }}>
                <div style={{ flex: "1 1 340px" }}>
                  <div className="h2">Best-of (MIDI)</div>
                  <table className="table">
                    <thead><tr><th>Fichier</th><th>Actions</th></tr></thead>
                    <tbody>
                      {bestFiles.map(f => (
                        <tr key={f.rel_path}>
                          <td>{f.name}</td>
                          <td>
                            <div className="row">
                              <button className="btn secondary" onClick={() => play(f)}>Play</button>
                              <a className="btn" href={reportsUrl(f.rel_path)} download>Download</a>
                            </div>
                          </td>
                        </tr>
                      ))}
                      {!bestFiles.length && (
                        <tr><td colSpan="2" className="small">Aucun MIDI best_of trouvé.</td></tr>
                      )}
                    </tbody>
                  </table>
                  {playInfo && (
                    <div className="small" style={{ marginTop: 8 }}>
                      Lecture: {playInfo.file} — notes={playInfo.notes}, tracks={playInfo.tracks}, duration≈{playInfo.duration.toFixed(2)}s
                    </div>
                  )}
                </div>

                <div style={{ flex: "1 1 340px" }}>
                  <div className="h2">Figures</div>
                  <div className="row">
                    <img className="img" alt="hist notes/sec" src={reportsUrl(`${selected.figures_dir}/hist_notes_per_sec.png`)} />
                    <img className="img" alt="hist total notes" src={reportsUrl(`${selected.figures_dir}/hist_total_notes.png`)} />
                    <img className="img" alt="scatter score vs nps" src={reportsUrl(`${selected.figures_dir}/scatter_score_vs_nps.png`)} />
                  </div>
                </div>
              </div>
            </>
          )}
        </div>
      </div>

      <div className="card" style={{ marginTop: 12 }}>
        <div className="small">
          Backend: http://localhost:8000 — Static: /reports/… — Front: http://localhost:5173
        </div>
      </div>
    </div>
  );
}
