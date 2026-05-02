'use client';
import { useEffect, useState } from 'react';
import { Wifi, Shield, Trash2 } from 'lucide-react';
import { api } from '../lib/api';

export default function LiveRooms({ onModerate }: { onModerate: (id: string) => void }) {
  const [rooms, setRooms] = useState<any[]>([]);
  const [ping, setPing] = useState('...');
  const [load, setLoad] = useState('...');

  useEffect(() => {
    const fetch = async () => {
      try {
        const start = Date.now();
        const res = await api.getRooms();
        const latency = Date.now() - start;
        setPing(`${latency}ms`);
        
        if (res.load_avg !== undefined) {
          const loadAvg = res.load_avg;
          setLoad(loadAvg < 1 ? 'Optimal' : loadAvg < 3 ? 'Moderate' : 'Heavy');
        }
        
        setRooms(res.rooms || []);
      } catch {}
    };
    fetch();
    const t = setInterval(fetch, 5000);
    return () => clearInterval(t);
  }, []);

  async function removeRoom(code: string) {
    if (!confirm('Force close this lobby?')) return;
    try {
      await api.deleteRoom(code);
    } catch {}
  }

  return (
    <section>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, marginBottom: '2rem' }}>
        <div className="glass-card" style={{ background: 'rgba(0,0,0,0.2)' }}>
          <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Active Rooms</div>
          <div style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--accent-primary)' }}>{rooms.length}</div>
        </div>
        <div className="glass-card" style={{ background: 'rgba(0,0,0,0.2)' }}>
          <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Server Load</div>
          <div style={{ fontSize: '1.5rem', fontWeight: 700, color: load === 'Optimal' ? 'var(--success)' : load === 'Moderate' ? '#eab308' : 'var(--danger)' }}>{load}</div>
        </div>
        <div className="glass-card" style={{ background: 'rgba(0,0,0,0.2)' }}>
          <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Ping</div>
          <div style={{ fontSize: '1.5rem', fontWeight: 700 }}>{ping}</div>
        </div>
      </div>

      <div className="glass-card">
        <div className="glass-header">
          <Wifi size={18} style={{ color: 'var(--success)' }} /> Live Multiplayer Sessions
        </div>
      {rooms.length === 0 && <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', textAlign: 'center', padding: '1rem' }}>No active rooms currently hosted.</p>}
      {rooms.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Room Code</th>
              <th>Host/Title</th>
              <th>Players</th>
              <th style={{ textAlign: 'right' }}>Moderate</th>
            </tr>
          </thead>
          <tbody>
            {rooms.map(r => (
              <tr key={r.room_id}>
                <td style={{ fontFamily: 'monospace', fontWeight: 600 }}>{r.room_code}</td>
                <td>{r.title}</td>
                <td>
                  <span className="badge badge-info">{r.player_count} / {r.max_players}</span>
                </td>
                <td style={{ textAlign: 'right' }}>
                  <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
                    <button className="btn-outline" style={{ padding: '6px' }} title="Moderate Room" onClick={() => onModerate(r.room_id)}>
                      <Shield size={16} />
                    </button>
                    <button className="btn-danger" style={{ padding: '6px', cursor: 'pointer', borderRadius: 8 }} onClick={() => removeRoom(r.room_code)} title="Kill Room">
                      <Trash2 size={16} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
      </div>
    </section>
  );
}
