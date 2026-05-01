'use client';
import { useEffect, useRef, useState } from 'react';
import axios from 'axios';
import { Settings, Users, Activity, Crosshair, Wifi, LogOut, Shield, Trash2, Plus, Server, Skull, Edit3, Check } from 'lucide-react';

const API = process.env.NEXT_PUBLIC_LOBBY_API_URL || 
  (typeof window !== 'undefined' ? `http://${window.location.hostname}:3000` : 'http://localhost:3000');

const authHeader = () => ({
  Authorization: `Bearer ${localStorage.getItem('moon_token')}`
});

// ─── Sub-components ───────────────────────────────────────────────────────────

function SettingsPanel() {
  const [staff, setStaff] = useState<any[]>([]);
  const [newAdmin, setNewAdmin] = useState({ user: '', pass: '', level: 1 });
  const [loading, setLoading] = useState(false);

  const fetchStaff = async () => {
    try {
      const res = await axios.get(`${API}/admin/staff`, { headers: authHeader() });
      setStaff(res.data.staff || []);
    } catch {}
  };

  useEffect(() => { fetchStaff(); }, []);

  async function addStaff() {
    if (!newAdmin.user || !newAdmin.pass) return;
    setLoading(true);
    try {
      await axios.post(`${API}/admin/staff`, 
        { username: newAdmin.user, password: newAdmin.pass, role_level: +newAdmin.level }, 
        { headers: authHeader() }
      );
      setNewAdmin({ user: '', pass: '', level: 1 });
      fetchStaff();
    } catch (e: any) { alert(e.response?.data?.error || 'Failed to add admin'); }
    finally { setLoading(false); }
  }

  async function deleteStaff(id: string) {
    if (!confirm('Permanently remove this staff member?')) return;
    try {
      await axios.delete(`${API}/admin/staff/${id}`, { headers: authHeader() });
      fetchStaff();
    } catch {}
  }

  return (
    <section className="glass-card">
      <div className="glass-header">
        <Settings size={18} className="text-accent-primary" /> Staff Management
      </div>
      
      <div style={{ marginBottom: '2rem' }}>
        <h4 style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: 12, fontWeight: 500 }}>ADD NEW ADMINISTRATOR</h4>
        <div style={{ display: 'flex', gap: 12 }}>
          <input className="input-field" placeholder="Username" 
            value={newAdmin.user} onChange={e => setNewAdmin({...newAdmin, user: e.target.value})} />
          <input className="input-field" placeholder="Password" type="password"
            value={newAdmin.pass} onChange={e => setNewAdmin({...newAdmin, pass: e.target.value})} />
          <button className="btn-primary" onClick={addStaff} disabled={loading}><Plus size={16} /> Add</button>
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th>User</th>
            <th>Role Level</th>
            <th style={{ width: 80, textAlign: 'center' }}>Actions</th>
          </tr>
        </thead>
        <tbody>
          {staff.map(s => (
            <tr key={s.user_id}>
              <td style={{ fontWeight: 500 }}>{s.username}</td>
              <td>
                {s.role_level === 2 
                  ? <span className="badge badge-success">SuperAdmin</span> 
                  : <span className="badge badge-info">Admin</span>}
              </td>
              <td style={{ textAlign: 'center' }}>
                <button className="btn-danger" style={{ padding: '4px 8px', borderRadius: 6, cursor: 'pointer' }} 
                  onClick={() => deleteStaff(s.user_id)}>
                  <Trash2 size={14} />
                </button>
              </td>
            </tr>
          ))}
          {staff.length === 0 && (
            <tr><td colSpan={3} style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No staff members found.</td></tr>
          )}
        </tbody>
      </table>
    </section>
  );
}

function LiveRooms({ onModerate }: { onModerate: (id: string) => void }) {
  const [rooms, setRooms] = useState<any[]>([]);
  const [ping, setPing] = useState('...');
  const [load, setLoad] = useState('...');

  useEffect(() => {
    const fetch = async () => {
      try {
        const start = Date.now();
        const res = await axios.get(`${API}/admin/rooms`, { headers: authHeader() });
        const latency = Date.now() - start;
        setPing(`${latency}ms`);
        
        if (res.data.load_avg !== undefined) {
          const loadAvg = res.data.load_avg;
          setLoad(loadAvg < 1 ? 'Optimal' : loadAvg < 3 ? 'Moderate' : 'Heavy');
        }
        
        setRooms(res.data.rooms || []);
      } catch {}
    };
    fetch();
    const t = setInterval(fetch, 5000);
    return () => clearInterval(t);
  }, []);

  async function removeRoom(code: string) {
    if (!confirm('Force close this lobby?')) return;
    try {
      await axios.delete(`${API}/admin/rooms/${code}`, { headers: authHeader() });
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



function PlayerSearch() {
  const [q, setQ] = useState('');
  const [players, setPlayers] = useState<any[]>([]);
  const qRef = useRef(q);

  const fetchPlayers = async () => {
    try {
      const res = await axios.get(`${API}/admin/players/search?q=${qRef.current}`, { headers: authHeader() });
      setPlayers((res.data.players || []).filter((p: any) => p.role_level === 0));
    } catch {}
  };

  // Load immediately on mount, then poll every 5s
  useEffect(() => {
    fetchPlayers();
    const t = setInterval(fetchPlayers, 5000);
    return () => clearInterval(t);
  }, []);

  // Re-fetch when filter changes
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
              <tr key={p.user_id}>
                <td style={{ fontFamily: 'monospace', fontSize: '0.85rem' }} title={p.user_id}>{p.user_id.substring(0,8)}</td>
                <td style={{ fontWeight: 600 }}>{p.username}</td>
                <td>{p.email || 'N/A'}</td>
                <td>{p.created_at ? new Date(p.created_at).toLocaleDateString() : 'N/A'}</td>
                <td>
                  {p.active_bans > 0
                    ? <span className="badge badge-danger">Banned</span>
                    : <span className="badge badge-success">Active</span>}
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

function MobCard({ mobType, isEditing }: { mobType: string, isEditing: boolean }) {
  const [stats, setStats] = useState({ health: '', speed: '', damage: '', xp_reward: '' });
  const [msg, setMsg] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    async function fetchStats() {
      try {
        const res = await axios.get(`${API}/admin/mobs/${mobType}`, { headers: authHeader() });
        if (res.data.mob) {
          setStats({
            health: res.data.mob.health || '',
            speed: res.data.mob.speed || '',
            damage: res.data.mob.damage || '',
            xp_reward: res.data.mob.xp_reward || ''
          });
        }
      } catch (e) {}
    }
    fetchStats();
  }, [mobType]);

  async function save() {
    setLoading(true);
    try {
      await axios.patch(`${API}/admin/mobs/${mobType}`,
        { health: +stats.health || undefined, speed: +stats.speed || undefined,
          damage: +stats.damage || undefined, xp_reward: +stats.xp_reward || undefined },
        { headers: authHeader() }
      );
      setMsg('Updated');
    } catch { setMsg('Error'); }
    setLoading(false);
    setTimeout(() => setMsg(''), 3000);
  }

  useEffect(() => {
    if (!isEditing && msg === '') {
      // Potentially save here if values changed, but for now we'll rely on the user manual save
    }
    const handleSave = () => { if (isEditing) save(); };
    window.addEventListener('moon-save-mobs', handleSave);
    return () => window.removeEventListener('moon-save-mobs', handleSave);
  }, [isEditing, stats]);

  return (
    <div className="glass-card" style={{ padding: '0.875rem', background: 'rgba(0,0,0,0.2)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
        <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: mobType === 'boss' ? 'var(--danger)' : 'var(--accent-primary)', textTransform: 'capitalize', margin: 0 }}>{mobType}</h3>
        {isEditing && <span style={{ fontSize: '0.75rem', color: msg === 'Error' ? 'var(--danger)' : 'var(--success)', fontWeight: 600 }}>{msg}</span>}
      </div>
      
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: isEditing ? '1rem' : 0 }}>
        {(['health','speed','damage','xp_reward'] as const).map(field => (
          <div key={field}>
            <label style={{ fontSize: '0.6rem', color: 'var(--text-muted)', display: 'block', marginBottom: 2, textTransform: 'uppercase', fontWeight: 700 }}>{field.replace('_', ' ')}</label>
            <input className="input-field" type="number" 
              disabled={!isEditing}
              style={{ 
                padding: '4px 8px', 
                fontSize: '0.8rem', 
                height: '32px',
                background: isEditing ? 'var(--bg-input)' : 'transparent',
                borderColor: isEditing ? 'var(--border-light)' : 'transparent',
                cursor: isEditing ? 'text' : 'default'
              }}
              value={stats[field]} onChange={e => setStats(s => ({ ...s, [field]: e.target.value }))} />
          </div>
        ))}
      </div>
    </div>
  );
}

function MobTuner() {
  const mobs = ['slime', 'skeleton', 'boss', 'bat', 'ghost', 'golem']; 
  const [search, setSearch] = useState('');
  const [isEditing, setIsEditing] = useState(false);
  
  const filteredMobs = mobs.filter(m => m.toLowerCase().includes(search.toLowerCase()));

  const toggleEdit = () => {
    if (isEditing) {
      // Trigger save on all cards
      window.dispatchEvent(new CustomEvent('moon-save-mobs'));
    }
    setIsEditing(!isEditing);
  };

  return (
    <section>
      <div style={{ marginBottom: '1rem' }}>
        <button className="btn-outline" onClick={toggleEdit} 
          style={{ background: isEditing ? 'var(--accent-primary)' : 'transparent', color: isEditing ? 'white' : 'var(--text-main)', border: 'none' }}>
          {isEditing ? <Check size={16} /> : <Edit3 size={16} />}
          {isEditing ? 'Confirm Changes' : 'Edit Parameters'}
        </button>
      </div>

      <div style={{ display: 'flex', justifyContent: 'flex-start', marginBottom: '1.5rem' }}>
        <input className="input-field" 
          style={{ background: 'transparent', border: '1px solid var(--border-light)', borderRadius: 6, width: '280px', fontSize: '0.85rem' }}
          placeholder="Filter mobs..." 
          value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, maxHeight: 'calc(100vh - 200px)', overflowY: 'auto', paddingRight: '0.5rem' }}>
        {filteredMobs.map(m => (
          <MobCard key={m} mobType={m} isEditing={isEditing} />
        ))}
        {filteredMobs.length === 0 && (
          <div style={{ gridColumn: 'span 2', textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
            No mobs found matching "{search}"
          </div>
        )}
      </div>
    </section>
  );
}

function BroadcastPanel() {
  const [msg, setMsg] = useState('');
  async function send() {
    if (!msg.trim()) return;
    try {
      await axios.post(`${API}/admin/broadcast`, { message: msg }, { headers: authHeader() });
      setMsg('');
      alert('Broadcast sent!');
    } catch {}
  }
  return (
    <section className="glass-card">
      <div className="glass-header">
        <Activity size={18} className="text-accent-primary" /> Global Server Broadcast
      </div>
      <div style={{ display: 'flex', gap: 12 }}>
        <input className="input-field" value={msg} onChange={e => setMsg(e.target.value)}
          placeholder="Enter a message to broadcast to all connected players..." />
        <button className="btn-primary" onClick={send}>Send Broadcast</button>
      </div>
    </section>
  );
}

function GraveyardPanel() {
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
      await axios.post(`${API}/admin/ban`, { user_id: targetId, reason }, { headers: authHeader() });
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
      await axios.post(`${API}/admin/player_action`, { user_id: targetId, action: 'kick', payload: {} }, { headers: authHeader() });
      addLog(`Kicked player ${targetId}`);
      setTargetId('');
    } catch (e: any) { 
      addLog(`Failed to kick ${targetId}: ${e.response?.data?.error || 'Error'}`); 
    }
  }

  return (
    <section className="glass-card">
      <div className="glass-header" style={{ color: 'var(--danger)' }}>
        <Skull size={18} /> Graveyard (Punishment & Kicks)
      </div>
      
      <div style={{ marginBottom: '2rem' }}>
        <h4 style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: 12, fontWeight: 500 }}>TARGET PLAYER ID</h4>
        <div style={{ display: 'flex', gap: 12 }}>
          <input className="input-field" placeholder="Enter Player User ID..." 
            value={targetId} onChange={e => setTargetId(e.target.value)} style={{ flex: 1 }} />
          <button className="btn-danger" onClick={ban}><Shield size={16} /> Ban</button>
          <button className="btn-outline" style={{ borderColor: '#ef4444', color: '#ef4444' }} onClick={kick}><LogOut size={16} /> Kick</button>
        </div>
      </div>

      <div>
        <h4 style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: 12, fontWeight: 500 }}>ACTION LOGS</h4>
        <div style={{ background: 'rgba(0,0,0,0.4)', borderRadius: 8, padding: '1rem', minHeight: '200px', maxHeight: '400px', overflowY: 'auto', fontFamily: 'monospace', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
          {logs.length === 0 && <div>No recent actions.</div>}
          {logs.map((log, i) => (
            <div key={i} style={{ marginBottom: 4 }}>{log}</div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─── Dashboard layout ─────────────────────────────────────────────────────────
export default function DashboardPage() {
  const [view, setView] = useState<'overview' | 'players' | 'mobs' | 'broadcast' | 'settings' | 'moderate' | 'graveyard'>('overview');
  const [roomsCount, setRoomsCount] = useState(0);
  const [uptimeStr, setUptimeStr] = useState('Checking...');
  const [moderateRoomId, setModerateRoomId] = useState<string | null>(null);

  useEffect(() => {
    if (!localStorage.getItem('moon_token')) window.location.href = '/';
    
    // Fetch quick stats for sidebar
    const fetchStats = async () => {
      try {
        const res = await axios.get(`${API}/admin/rooms`, { headers: authHeader() });
        setRoomsCount(res.data.rooms?.length || 0);
        
        if (res.data.process_uptime) {
          const up = res.data.process_uptime;
          const d = Math.floor(up / 86400);
          const h = Math.floor((up % 86400) / 3600);
          const m = Math.floor((up % 3600) / 60);
          if (d > 0) setUptimeStr(`${d}d ${h}h`);
          else if (h > 0) setUptimeStr(`${h}h ${m}m`);
          else setUptimeStr(`${m}m`);
        }
      } catch {}
    };
    fetchStats();
    const t = setInterval(fetchStats, 5000);
    return () => clearInterval(t);
  }, []);

  function logout() {
    localStorage.removeItem('moon_token');
    localStorage.removeItem('moon_user');
    window.location.href = '/';
  }

  const getPageTitle = () => {
    switch(view) {
      case 'overview': return { title: 'Overview' };
      case 'players': return { title: 'Player Database' };
      case 'mobs': return { title: 'Live Mob Tuning' };
      case 'broadcast': return { title: 'Global Broadcast' };
      case 'moderate': return { title: 'Room Moderation' };
      case 'settings': return { title: 'System Settings' };
    }
  }

  const pageTitle = getPageTitle()?.title ?? '';

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <aside style={{ position: 'fixed', top: 0, left: 0, bottom: 0, width: 260, borderRight: '1px solid var(--border-light)', background: 'var(--bg-card)', display: 'flex', flexDirection: 'column', padding: '2rem 1.5rem', zIndex: 50 }}>
        <div style={{ marginBottom: '3rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ background: 'var(--accent-primary)', width: 36, height: 36, borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 0 15px rgba(96, 165, 250, 0.2)' }}>
              <Server size={20} color="white" />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.85rem', letterSpacing: '-0.01em', color: 'var(--text-main)' }}>SYSTEM ONLINE</div>
              <div style={{ fontSize: '0.7rem', color: 'var(--accent-primary)', fontWeight: 600 }}>Uptime: {uptimeStr}</div>
            </div>
          </div>
          <button onClick={() => setView('settings')} style={{ background: 'transparent', border: 'none', color: view === 'settings' ? 'var(--text-main)' : 'var(--text-muted)', cursor: 'pointer', padding: 4 }}>
            <Settings size={18} />
          </button>
        </div>
        
        <nav style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <button className={`btn-outline ${view === 'overview' ? 'active' : ''}`} 
            onClick={() => setView('overview')} style={{ border: 'none', justifyContent: 'flex-start' }}>
            <Activity size={18} /> Overview
          </button>
          <button className={`btn-outline ${view === 'players' ? 'active' : ''}`} 
            onClick={() => setView('players')} style={{ border: 'none', justifyContent: 'flex-start' }}>
            <Users size={18} /> Player Database
          </button>
          <button className={`btn-outline ${view === 'mobs' ? 'active' : ''}`} 
            onClick={() => setView('mobs')} style={{ border: 'none', justifyContent: 'flex-start' }}>
            <Crosshair size={18} /> Live Mob Tuning
          </button>
          <button className={`btn-outline ${view === 'broadcast' ? 'active' : ''}`} 
            onClick={() => setView('broadcast')} style={{ border: 'none', justifyContent: 'flex-start' }}>
            <Wifi size={18} /> Global Broadcast
          </button>
        </nav>

        <div style={{ flex: 1 }} />
        
        <div style={{ paddingTop: '1.5rem', borderTop: '1px solid var(--border-light)', display: 'flex', gap: 8 }}>
          <button className={`btn-outline ${view === 'graveyard' ? 'active' : ''}`} onClick={() => setView('graveyard')} style={{ border: 'none', background: 'rgba(255,255,255,0.05)', padding: '10px' }} title="Graveyard">
            <Skull size={18} />
          </button>
          <button className="btn-outline" onClick={logout} style={{ flex: 1, justifyContent: 'center', border: 'none', background: 'rgba(255,255,255,0.05)' }}>
            <LogOut size={16} /> Sign Out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main style={{ marginLeft: 260, flex: 1, overflowY: 'auto', padding: '2.5rem 3rem' }}>

        {view === 'overview' && <LiveRooms onModerate={(id) => { setModerateRoomId(id); setView('moderate'); }} />}
        {view === 'players' && <PlayerSearch />}
        {view === 'moderate' && moderateRoomId && <ModerateRoom roomId={moderateRoomId} onBack={() => setView('overview')} />}
        {view === 'mobs' && <MobTuner />}
        {view === 'broadcast' && <BroadcastPanel />}
        {view === 'settings' && <SettingsPanel />}
        {view === 'graveyard' && <GraveyardPanel />}
      </main>
    </div>
  );
}

function ModerateRoom({ roomId, onBack }: { roomId: string, onBack: () => void }) {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetch = async () => {
      try {
        const res = await axios.get(`${API}/admin/rooms/${roomId}/stats`, { headers: authHeader() });
        setStats(res.data);
      } catch (e) {
        // Fallback dummy data for visualization
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
              <tr key={p.id}>
                <td style={{ fontWeight: 600 }}>{p.name}</td>
                <td><span className="badge badge-info">Lv. {p.lvl}</span></td>
                <td>{p.kills}</td>
                <td>{p.dmg?.toLocaleString()}</td>
                <td>{p.gold}g</td>
                <td style={{ textAlign: 'right' }}>
                  <button className="btn-danger" style={{ padding: '4px 8px', fontSize: '0.75rem' }}>Kick</button>
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
