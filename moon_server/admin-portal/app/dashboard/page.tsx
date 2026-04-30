'use client';
import { useEffect, useState } from 'react';
import axios from 'axios';
import { Settings, Users, Activity, Crosshair, Wifi, LogOut, Shield, Trash2, Plus, Server } from 'lucide-react';

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

function LiveRooms() {
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
              <th>Quick Actions</th>
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
                <td>
                  <SpawnMobBtn room_id={r.room_id} />
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

function SpawnMobBtn({ room_id }: { room_id: string }) {
  const [mob, setMob] = useState('slime');
  const [busy, setBusy] = useState(false);
  async function spawn() {
    setBusy(true);
    try {
      await axios.post(`${API}/admin/spawn_mob`, { room_id, mob_type: mob, count: 1 }, { headers: authHeader() });
    } finally { setBusy(false); }
  }
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
      <select className="input-field" style={{ padding: '4px 8px', width: 'auto' }} value={mob} onChange={e => setMob(e.target.value)}>
        <option value="slime">Slime</option>
        <option value="skeleton">Skeleton</option>
        <option value="boss">Boss</option>
      </select>
      <button className="btn-outline" onClick={spawn} disabled={busy} style={{ padding: '4px 8px' }}>
        Spawn
      </button>
    </div>
  );
}

function PlayerSearch() {
  const [q, setQ] = useState('');
  const [players, setPlayers] = useState<any[]>([]);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  async function search(e: React.FormEvent) {
    e.preventDefault();
    try {
      const res = await axios.get(`${API}/admin/players/search?q=${q}`, { headers: authHeader() });
      setPlayers(res.data.players || []);
    } catch {}
  }

  async function ban(user_id: string) {
    const reason = prompt('Ban reason:');
    if (!reason) return;
    try {
      await axios.post(`${API}/admin/ban`, { user_id, reason }, { headers: authHeader() });
      alert('Player banned');
    } catch (e: any) { alert(e.response?.data?.error || 'Failed'); }
  }

  async function wipe(user_id: string) {
    if (!confirm("WARNING: This will permanently reset this player's level, xp, and coins to zero. Are you sure?")) return;
    try {
      await axios.post(`${API}/admin/players/${user_id}/wipe`, {}, { headers: authHeader() });
      alert('Cloud save wiped.');
    } catch (e: any) { alert('Failed'); }
  }

  async function sendAction(user_id: string, action: string, payload: any) {
    try {
      await axios.post(`${API}/admin/player_action`, { user_id, action, payload }, { headers: authHeader() });
      alert(`${action} command sent to live servers.`);
    } catch (e: any) { alert('Failed to send command.'); }
  }

  return (
    <section className="glass-card" style={{ display: 'flex', flexDirection: 'column' }}>
      <div className="glass-header">
        <Users size={18} className="text-accent-primary" /> Player Database
      </div>
      <form onSubmit={search} style={{ display: 'flex', gap: 12, marginBottom: '1.5rem' }}>
        <input className="input-field" value={q} onChange={e => setQ(e.target.value)} placeholder="Search username or email..." />
        <button type="submit" className="btn-primary">Search</button>
      </form>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, overflowY: 'auto', flex: 1 }}>
        {players.map(p => (
          <div key={p.user_id} style={{ display: 'flex', flexDirection: 'column', background: 'rgba(0,0,0,0.2)', borderRadius: 8, overflow: 'hidden' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', cursor: 'pointer' }} onClick={() => setExpandedId(expandedId === p.user_id ? null : p.user_id)}>
              <div>
                <div style={{ fontWeight: 600, marginBottom: 4, display: 'flex', alignItems: 'center', gap: 8 }}>
                  {p.username}
                  {p.active_bans > 0
                    ? <span className="badge badge-danger">Banned</span>
                    : <span className="badge badge-success">Active</span>}
                </div>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                  ID: <span style={{ fontFamily: 'monospace' }}>{p.user_id.substring(0,8)}</span> | Display: {p.display_name}
                </div>
              </div>
              <button className="btn-outline" style={{ padding: '6px 12px', fontSize: '0.8rem' }}>
                {expandedId === p.user_id ? 'Close' : 'God Mode'}
              </button>
            </div>
            
            {expandedId === p.user_id && (
              <div style={{ padding: '1rem', background: 'rgba(0,0,0,0.4)', borderTop: '1px solid rgba(255,255,255,0.05)', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
                {/* Live Manipulation */}
                <div>
                  <h4 style={{ fontSize: '0.8rem', color: 'var(--accent-primary)', marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Live Manipulation</h4>
                  <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
                    <input id={`item-${p.user_id}`} className="input-field" placeholder="Item ID (e.g. coins)" style={{ flex: 1, padding: '4px 8px' }} />
                    <input id={`amt-${p.user_id}`} className="input-field" type="number" placeholder="Amount" defaultValue={100} style={{ width: 80, padding: '4px 8px' }} />
                    <button className="btn-primary" style={{ padding: '4px 12px' }} onClick={() => {
                      const elId = document.getElementById(`item-${p.user_id}`) as HTMLInputElement;
                      const elAmt = document.getElementById(`amt-${p.user_id}`) as HTMLInputElement;
                      if(elId.value) sendAction(p.user_id, 'give_item', { item_id: elId.value, amount: parseInt(elAmt.value) });
                    }}>Give</button>
                  </div>
                  
                  <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
                    <select id={`stat-${p.user_id}`} className="input-field" style={{ flex: 1, padding: '4px 8px' }}>
                      <option value="max_health">Max Health</option>
                      <option value="move_speed">Move Speed</option>
                      <option value="damage_multiplier">Damage Mult</option>
                    </select>
                    <input id={`val-${p.user_id}`} className="input-field" type="number" placeholder="Value" defaultValue={500} style={{ width: 80, padding: '4px 8px' }} />
                    <button className="btn-primary" style={{ padding: '4px 12px' }} onClick={() => {
                      const elSt = document.getElementById(`stat-${p.user_id}`) as HTMLSelectElement;
                      const elV = document.getElementById(`val-${p.user_id}`) as HTMLInputElement;
                      if(elV.value) sendAction(p.user_id, 'set_stat', { stat: elSt.value, value: parseFloat(elV.value) });
                    }}>Set</button>
                  </div>

                  <div style={{ display: 'flex', gap: 8 }}>
                    <input id={`x-${p.user_id}`} className="input-field" type="number" placeholder="X Coord" defaultValue={0} style={{ flex: 1, padding: '4px 8px' }} />
                    <input id={`y-${p.user_id}`} className="input-field" type="number" placeholder="Y Coord" defaultValue={0} style={{ flex: 1, padding: '4px 8px' }} />
                    <button className="btn-primary" style={{ padding: '4px 12px' }} onClick={() => {
                      const elX = document.getElementById(`x-${p.user_id}`) as HTMLInputElement;
                      const elY = document.getElementById(`y-${p.user_id}`) as HTMLInputElement;
                      sendAction(p.user_id, 'teleport', { x: parseFloat(elX.value), y: parseFloat(elY.value) });
                    }}>Teleport</button>
                  </div>
                </div>

                {/* Moderation */}
                <div>
                  <h4 style={{ fontSize: '0.8rem', color: 'var(--danger)', marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Moderation & Data</h4>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    <button className="btn-outline" style={{ borderColor: 'var(--danger)', color: 'var(--danger)', justifyContent: 'center' }} onClick={() => ban(p.user_id)}>
                      Ban Player (Kicks & Disables Login)
                    </button>
                    <button className="btn-outline" style={{ borderColor: '#ef4444', color: '#ef4444', justifyContent: 'center' }} onClick={() => wipe(p.user_id)}>
                      Wipe Cloud Save (Reset Lvl/Coins)
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </section>
  );
}

function MobTuner() {
  const mobs = ['slime', 'skeleton', 'boss'];
  const [selected, setSelected] = useState('slime');
  const [stats, setStats] = useState({ health: '', speed: '', damage: '', xp_reward: '' });
  const [msg, setMsg] = useState('');

  // Fetch current stats when mob is selected
  useEffect(() => {
    async function fetchStats() {
      try {
        const res = await axios.get(`${API}/admin/mobs/${selected}`, { headers: authHeader() });
        if (res.data.mob) {
          setStats({
            health: res.data.mob.health || '',
            speed: res.data.mob.speed || '',
            damage: res.data.mob.damage || '',
            xp_reward: res.data.mob.xp_reward || ''
          });
        }
      } catch (e) {
        setStats({ health: '', speed: '', damage: '', xp_reward: '' });
      }
    }
    fetchStats();
  }, [selected]);

  async function save() {
    try {
      await axios.patch(`${API}/admin/mobs/${selected}`,
        { health: +stats.health || undefined, speed: +stats.speed || undefined,
          damage: +stats.damage || undefined, xp_reward: +stats.xp_reward || undefined },
        { headers: authHeader() }
      );
      setMsg('Parameters updated globally.');
    } catch { setMsg('Failed to update.'); }
    setTimeout(() => setMsg(''), 3000);
  }

  return (
    <section className="glass-card">
      <div className="glass-header">
        <Crosshair size={18} className="text-accent-primary" /> Live Mob Tuning
      </div>
      <div style={{ marginBottom: '1.5rem' }}>
        <select className="input-field" style={{ width: '100%', maxWidth: 300 }} value={selected} onChange={(e) => setSelected(e.target.value)}>
          {mobs.map(m => (
            <option key={m} value={m}>
              {m.charAt(0).toUpperCase() + m.slice(1)}
            </option>
          ))}
        </select>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: '1.5rem' }}>
        {(['health','speed','damage','xp_reward'] as const).map(field => (
          <div key={field}>
            <label style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'block', marginBottom: 4, textTransform: 'uppercase', fontWeight: 600 }}>{field.replace('_', ' ')}</label>
            <input className="input-field" type="number" placeholder="Leave blank to keep current"
              value={stats[field]} onChange={e => setStats(s => ({ ...s, [field]: e.target.value }))} />
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontSize: '0.85rem', color: msg.includes('Failed') ? 'var(--danger)' : 'var(--success)' }}>{msg}</span>
        <button className="btn-primary" onClick={save}>Push Configuration</button>
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

// ─── Dashboard layout ─────────────────────────────────────────────────────────
export default function DashboardPage() {
  const [view, setView] = useState<'overview' | 'players' | 'mobs' | 'broadcast' | 'settings'>('overview');
  const [roomsCount, setRoomsCount] = useState(0);
  const [uptimeStr, setUptimeStr] = useState('Checking...');

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
      case 'overview': return { title: 'Overview', desc: 'Monitor live game infrastructure.' };
      case 'players': return { title: 'Player Database', desc: 'Search and manage player accounts.' };
      case 'mobs': return { title: 'Live Mob Tuning', desc: 'Adjust mob stats globally in real-time.' };
      case 'broadcast': return { title: 'Global Broadcast', desc: 'Send announcements to all connected players.' };
      case 'settings': return { title: 'System Settings', desc: 'Manage staff access and security policies.' };
    }
  }

  const { title, desc } = getPageTitle();

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <aside style={{ position: 'fixed', top: 0, left: 0, bottom: 0, width: 260, borderRight: '1px solid var(--border-light)', background: 'var(--bg-card)', display: 'flex', flexDirection: 'column', padding: '2rem 1.5rem', zIndex: 50 }}>
        <div style={{ marginBottom: '3rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ background: 'var(--accent-primary)', width: 36, height: 36, borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Server size={20} color="white" />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '1.1rem', letterSpacing: '-0.02em' }}>Moon Server</div>
              <div style={{ fontSize: '0.75rem', color: 'var(--success)' }}>● System Online</div>
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
        
        <div style={{ paddingTop: '1.5rem', borderTop: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '0.8rem', marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8, color: 'var(--text-muted)' }}>
             <Shield size={14} /> Administrator Access
          </div>
          <button className="btn-outline" onClick={logout} style={{ width: '100%', justifyContent: 'center', border: 'none', background: 'rgba(255,255,255,0.05)' }}>
            <LogOut size={16} /> Sign Out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main style={{ marginLeft: 260, flex: 1, overflowY: 'auto', padding: '2.5rem 3rem' }}>
        <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h1 style={{ fontSize: '2rem', fontWeight: 700, margin: '0 0 0.5rem 0', letterSpacing: '-0.03em' }}>
              {title}
            </h1>
            <p style={{ color: 'var(--text-muted)', margin: 0, fontSize: '0.95rem' }}>
              {desc}
            </p>
          </div>
          <div style={{ background: 'var(--bg-card)', border: '1px solid var(--border-light)', borderRadius: 999, padding: '0.5rem 1rem', fontSize: '0.85rem', display: 'flex', gap: 12, alignItems: 'center' }}>
            <span><span style={{ color: 'var(--text-muted)' }}>Uptime:</span> {uptimeStr}</span>
          </div>
        </header>

        {view === 'overview' && <LiveRooms />}
        {view === 'players' && <PlayerSearch />}
        {view === 'mobs' && <MobTuner />}
        {view === 'broadcast' && <BroadcastPanel />}
        {view === 'settings' && <SettingsPanel />}
      </main>
    </div>
  );
}
