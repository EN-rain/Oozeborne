'use client';
import { useState } from 'react';
import { Skull, LogOut, Shield } from 'lucide-react';
import { api } from '../lib/api';

export default function GraveyardPanel() {
  const [targetId, setTargetId] = useState('');
  const [logs, setLogs] = useState<string[]>([]);

  const addLog = (msg: string) => {
    setLogs(prev => [`[${new Date().toLocaleTimeString()}] ${msg}`, ...prev]);
  };

  async function ban() {
    if (!targetId.trim()) return;
    const reason = prompt('Ban reason:');
    if (!reason) return;
    try {
      await api.banPlayer({ user_id: targetId, reason });
      addLog(`Banned player ${targetId} for: ${reason}`);
      setTargetId('');
    } catch (e: any) { 
      addLog(`Failed to ban ${targetId}: ${e.response?.data?.error || 'Error'}`); 
    }
  }

  async function kick() {
    if (!targetId.trim()) return;
    if (!confirm('Kick this player from current session?')) return;
    try {
      await api.playerAction({ user_id: targetId, action: 'kick', payload: {} });
      addLog(`Kicked player ${targetId}`);
      setTargetId('');
    } catch (e: any) { 
      addLog(`Failed to kick ${targetId}: ${e.response?.data?.error || 'Error'}`); 
    }
  }

  return (
    <section className="glass-card" style={{ border: '1px solid var(--border-light)' }}>
      <div className="glass-header" style={{ color: 'var(--text-main)', opacity: 0.9 }}>
        <Skull size={18} /> Graveyard Control
      </div>
      
      <div style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: 24 }}>
        <div>
          <h4 style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginBottom: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Target Player</h4>
          <div style={{ display: 'flex', gap: 10 }}>
            <input className="input-field" placeholder="Enter User ID (e.g. user_123...)" 
              value={targetId} onChange={e => setTargetId(e.target.value)} 
              style={{ flex: 1, background: 'rgba(0,0,0,0.2)', height: '42px' }} />
            <button className="btn-outline" onClick={kick} 
              style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '0 20px', height: '42px', fontSize: '0.85rem' }}>
              <LogOut size={16} /> Kick
            </button>
            <button className="btn-outline" onClick={ban} 
              style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '0 20px', height: '42px', fontSize: '0.85rem', background: 'rgba(255,255,255,0.05)' }}>
              <Shield size={16} /> Ban Player
            </button>
          </div>
        </div>

        <div>
          <h4 style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginBottom: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Security Logs</h4>
          <div style={{ 
            background: 'rgba(0,0,0,0.3)', borderRadius: 8, padding: '1rem', height: '300px', overflowY: 'auto', 
            fontFamily: 'monospace', fontSize: '0.8rem', color: 'var(--text-muted)', border: '1px solid var(--border-light)' 
          }}>
            {logs.length === 0 && <div style={{ opacity: 0.5 }}>System idle. Awaiting actions...</div>}
            {logs.map((log, i) => (
              <div key={i} style={{ marginBottom: 6, borderBottom: '1px solid rgba(255,255,255,0.02)', paddingBottom: 4 }}>
                <span style={{ color: 'var(--accent-primary)', marginRight: 8 }}>{log.split(']')[0]}]</span>
                {log.split(']')[1]}
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
