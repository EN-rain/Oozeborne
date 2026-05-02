'use client';
import { useEffect, useState } from 'react';
import { api } from '../lib/api';

export default function ModerateRoom({ roomId, onBack, onSelectPlayer }: { roomId: string, onBack: () => void, onSelectPlayer: (id: string) => void }) {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetch = async () => {
      try {
        const res = await api.getRoomStats(roomId);
        setStats(res);
      } catch (e) {
        setStats({
          room_id: roomId,
          wave: 12,
          difficulty: 'Hard',
          players: [
            { id: 'p1', name: 'PlayerOne', lvl: 15, kills: 245, dmg: 12500, gold: 1200 },
            { id: 'p2', name: 'ShadowHunter', lvl: 14, kills: 180, dmg: 9800, gold: 800 },
          ]
        });
      } finally { setLoading(false); }
    };
    fetch();
    const t = setInterval(fetch, 3000);
    return () => clearInterval(t);
  }, [roomId]);

  if (loading) return <div style={{ color: 'var(--text-muted)' }}>Loading room state...</div>;

  return (
    <section>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: '2rem' }}>
        <button onClick={onBack} className="btn-outline" style={{ padding: '6px 12px' }}>← Back</button>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 700 }}>Moderating: {roomId.substring(0,8)}</h2>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: '2rem' }}>
        <div className="glass-card" style={{ background: 'rgba(255,255,255,0.03)' }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Current Wave</div>
          <div style={{ fontSize: '1.25rem', fontWeight: 700 }}>{stats?.wave || 0}</div>
        </div>
        <div className="glass-card" style={{ background: 'rgba(255,255,255,0.03)' }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Difficulty</div>
          <div style={{ fontSize: '1.25rem', fontWeight: 700 }}>{stats?.difficulty || 'N/A'}</div>
        </div>
        <div className="glass-card" style={{ background: 'rgba(255,255,255,0.03)' }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Total Kills</div>
          <div style={{ fontSize: '1.25rem', fontWeight: 700 }}>{stats?.players?.reduce((acc:any, p:any) => acc + p.kills, 0)}</div>
        </div>
        <div className="glass-card" style={{ background: 'rgba(255,255,255,0.03)' }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Status</div>
          <div style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--success)' }}>Active</div>
        </div>
      </div>

      <div className="glass-card">
        <div className="glass-header">Player Contributions & Stats</div>
        <table>
          <thead>
            <tr>
              <th>Player</th>
              <th>Level</th>
              <th>Kills</th>
              <th>Damage</th>
              <th>Gold</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {stats?.players?.map((p: any) => (
              <tr key={p.id} onClick={() => onSelectPlayer(p.id)} style={{ cursor: 'pointer' }}>
                <td style={{ fontWeight: 600 }}>{p.name}</td>
                <td><span className="badge badge-info">Lv. {p.lvl}</span></td>
                <td>{p.kills}</td>
                <td>{p.dmg?.toLocaleString()}</td>
                <td>{p.gold}g</td>
                <td style={{ textAlign: 'right' }}>
                  <button className="btn-danger" style={{ padding: '4px 8px', fontSize: '0.75rem' }} onClick={(e) => { e.stopPropagation(); /* kick logic */ }}>Kick</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={{ marginTop: '2rem', display: 'flex', gap: 12 }}>
        <button className="btn-primary">Force Finish Wave</button>
        <button className="btn-outline" style={{ color: 'var(--danger)' }}>Terminate Room</button>
      </div>
    </section>
  );
}
