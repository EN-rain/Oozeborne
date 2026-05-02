'use client';
import { useEffect, useState } from 'react';
import { api } from '../lib/api';

export default function PlayerDetailModal({ userId, onClose }: { userId: string, onClose: () => void }) {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.getPlayer(userId)
      .then(res => setData(res))
      .finally(() => setLoading(false));
  }, [userId]);

  if (loading) return null;

  const p = data?.player;

  return (
    <div style={{ 
      position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
      background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
      display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000,
      padding: '2rem'
    }} onClick={onClose}>
      <div style={{ 
        width: '100%', maxWidth: '600px', maxHeight: '90vh', overflowY: 'auto',
        background: 'var(--bg-main)', border: '1px solid var(--border-light)',
        borderRadius: 12, padding: '2.5rem', position: 'relative', boxShadow: '0 20px 40px rgba(0,0,0,0.4)'
      }} onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '2rem' }}>
          <div>
            <h2 style={{ margin: 0, fontSize: '1.5rem', fontWeight: 800 }}>{p?.username}</h2>
            <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', fontFamily: 'monospace' }}>{p?.user_id}</div>
          </div>
          {data?.is_online ? <span className="badge badge-success">Online</span> : <span className="badge">Offline</span>}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: '2rem' }}>
          <div className="glass-card" style={{ padding: '1rem', background: 'rgba(255,255,255,0.03)' }}>
            <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700, marginBottom: 8 }}>Progression</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>Level</span><span style={{ fontWeight: 700 }}>{p?.level || 1}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>XP</span><span style={{ fontWeight: 700 }}>{p?.xp || 0}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>Coins</span><span style={{ fontWeight: 700, color: '#fbbf24' }}>{p?.coins || 0}</span></div>
            </div>
          </div>
          <div className="glass-card" style={{ padding: '1rem', background: 'rgba(255,255,255,0.03)' }}>
            <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700, marginBottom: 8 }}>Account</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>Email</span><span style={{ fontWeight: 500 }}>{p?.email || 'N/A'}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>Created</span><span style={{ fontWeight: 500 }}>{new Date(p?.created_at).toLocaleDateString()}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>Bans</span><span style={{ fontWeight: 700, color: data?.bans?.length > 0 ? 'var(--danger)' : 'var(--success)' }}>{data?.bans?.length || 0}</span></div>
            </div>
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', background: 'rgba(255,255,255,0.03)' }}>
          <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700, marginBottom: 12 }}>Recent Matches</div>
          {data?.match_history?.length === 0 ? (
            <div style={{ fontSize: '0.8rem', opacity: 0.5 }}>No recent matches found.</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {data?.match_history?.map((m: any, i: number) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', padding: '4px 0', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                  <span>Wave {m.wave_reached}</span>
                  <span>{m.kills} Kills</span>
                  <span style={{ opacity: 0.6 }}>{new Date(m.started_at).toLocaleDateString()}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        <div style={{ marginTop: '2rem', display: 'flex', gap: 12 }}>
          <button className="btn-outline" style={{ flex: 1 }} onClick={onClose}>Close</button>
          <button className="btn-danger" style={{ flex: 1 }}>Wipe Progression</button>
        </div>
      </div>
    </div>
  );
}
