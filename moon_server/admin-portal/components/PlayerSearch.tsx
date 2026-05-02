'use client';
import { useEffect, useRef, useState } from 'react';
import { api } from '../lib/api';

export default function PlayerSearch({ onSelectPlayer }: { onSelectPlayer: (id: string) => void }) {
  const [q, setQ] = useState('');
  const [players, setPlayers] = useState<any[]>([]);
  const qRef = useRef(q);

  const fetchPlayers = async () => {
    try {
      const res = await api.searchPlayers(qRef.current);
      setPlayers((res.players || []).filter((p: any) => p.role_level === 0));
    } catch { }
  };

  useEffect(() => {
    fetchPlayers();
    const t = setInterval(fetchPlayers, 5000);
    return () => clearInterval(t);
  }, []);

  useEffect(() => {
    qRef.current = q;
    fetchPlayers();
  }, [q]);

  return (
    <section style={{ display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'flex-start', marginBottom: '1.5rem' }}>
        <input className="input-field"
          style={{ background: 'transparent', border: '1px solid var(--border-light)', borderRadius: 6, width: '280px', fontSize: '0.85rem' }}
          value={q} onChange={e => setQ(e.target.value)} placeholder="Filter players..." />
      </div>
      <div className="glass-card" style={{ flex: 1, overflowY: 'auto' }}>
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Username</th>
              <th>Email</th>
              <th>Date Created</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {players.map(p => (
              <tr key={p.user_id} onClick={() => onSelectPlayer(p.user_id)} style={{ cursor: 'pointer' }}>
                <td style={{ fontFamily: 'monospace', fontSize: '0.85rem' }} title={p.user_id}>{p.user_id.substring(0, 8)}</td>
                <td style={{ fontWeight: 600 }}>{p.username}</td>
                <td>{p.email || 'N/A'}</td>
                <td>{p.created_at ? new Date(p.created_at).toLocaleDateString() : 'N/A'}</td>
                <td>
                  {p.is_online
                    ? <span className="badge badge-success">Online</span>
                    : <span className="badge" style={{ background: 'rgba(148,163,184,0.1)', color: 'var(--text-muted)', border: '1px solid rgba(148,163,184,0.2)' }}>Offline</span>}
                </td>
              </tr>
            ))}
            {players.length === 0 && (
              <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No players found.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
