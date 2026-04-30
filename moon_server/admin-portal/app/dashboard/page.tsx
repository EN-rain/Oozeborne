'use client';
import { useEffect, useState } from 'react';
import axios from 'axios';
import { Settings, Users, Activity, Crosshair, Wifi, LogOut, Shield, Trash2, Plus } from 'lucide-react';

const API = process.env.NEXT_PUBLIC_LOBBY_API_URL || 'http://localhost:3000';

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
    <section className="terminal-card">
      <div className="terminal-header" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Settings size={16} /> SYSTEM_STAFF_MANAGEMENT
      </div>
      
      <div style={{ marginBottom: '2rem' }}>
        <h4 style={{ fontSize: '0.7rem', color: 'var(--terminal-dim)', marginBottom: 8 }}>CREATE_NEW_ADMIN</h4>
        <div style={{ display: 'flex', gap: 8 }}>
          <input className="terminal-input" placeholder="USERNAME" 
            value={newAdmin.user} onChange={e => setNewAdmin({...newAdmin, user: e.target.value})} />
          <input className="terminal-input" placeholder="PASSWORD" type="password"
            value={newAdmin.pass} onChange={e => setNewAdmin({...newAdmin, pass: e.target.value})} />
          <select className="terminal-input" style={{ width: 100 }}
            value={newAdmin.level} onChange={e => setNewAdmin({...newAdmin, level: +e.target.value})}>
            <option value={1}>ADMIN</option>
            <option value={2}>SUPER</option>
          </select>
          <button className="terminal-btn" onClick={addStaff} disabled={loading}><Plus size={14} /></button>
        </div>
      </div>

      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.875rem' }}>
        <thead>
          <tr style={{ textAlign: 'left', borderBottom: '1px solid var(--terminal-border)' }}>
            <th style={th}>USER</th>
            <th style={th}>LEVEL</th>
            <th style={th}>OPS</th>
          </tr>
        </thead>
        <tbody>
          {staff.map(s => (
            <tr key={s.user_id} style={{ borderBottom: '1px dashed var(--terminal-dim)' }}>
              <td style={td}>{s.username}</td>
              <td style={td}>
                {s.role_level === 2 ? <span style={{ color: 'var(--terminal-green)' }}>SUPER</span> : 'STAFF'}
              </td>
              <td style={td}>
                <button className="terminal-btn" style={{ color: 'var(--moon-danger)', padding: '2px 4px' }} 
                  onClick={() => deleteStaff(s.user_id)}>
                  <Trash2 size={12} />
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}

function LiveRooms() {
  const [rooms, setRooms] = useState<any[]>([]);
  useEffect(() => {
    const fetch = async () => {
      try {
        const res = await axios.get(`${API}/admin/rooms`, { headers: authHeader() });
        setRooms(res.data.rooms || []);
      } catch {}
    };
    fetch();
    const t = setInterval(fetch, 5000);
    return () => clearInterval(t);
  }, []);

  return (
    <section className="terminal-card">
      <div className="terminal-header" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Wifi size={16} /> Active_Rooms
      </div>
      {rooms.length === 0 && <p style={{ color: 'var(--terminal-dim)' }}>[ NO ACTIVE SESSIONS ]</p>}
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.875rem' }}>
        <thead>
          <tr style={{ textAlign: 'left', borderBottom: '1px solid var(--terminal-border)' }}>
            <th style={th}>CODE</th>
            <th style={th}>TITLE</th>
            <th style={th}>PLAYERS</th>
            <th style={th}>OPS</th>
          </tr>
        </thead>
        <tbody>
          {rooms.map(r => (
            <tr key={r.room_id} style={{ borderBottom: '1px dashed var(--terminal-dim)' }}>
              <td style={td}>{r.room_code}</td>
              <td style={td}>{r.title}</td>
              <td style={td}>{r.player_count}/{r.max_players}</td>
              <td style={td}>
                <SpawnMobBtn room_id={r.room_id} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
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
    <span style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      <select value={mob} onChange={e => setMob(e.target.value)} 
        style={{ background: 'transparent', color: 'var(--terminal-green)', border: '1px solid var(--terminal-dim)', outline: 'none' }}>
        <option value="slime">SLIME</option>
        <option value="skeleton">SKELETON</option>
        <option value="boss">BOSS</option>
      </select>
      <button className="terminal-btn" onClick={spawn} disabled={busy} style={{ fontSize: '0.7rem', padding: '2px 8px' }}>
        EXE_SPAWN
      </button>
    </span>
  );
}

function PlayerSearch() {
  const [q, setQ] = useState('');
  const [players, setPlayers] = useState<any[]>([]);

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

  return (
    <section className="terminal-card">
      <div className="terminal-header" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Users size={16} /> Player_Database
      </div>
      <form onSubmit={search} style={{ display: 'flex', gap: 8, marginBottom: '1rem' }}>
        <span style={{ marginRight: 4 }}>{'>'}</span>
        <input className="terminal-input" value={q} onChange={e => setQ(e.target.value)}
          placeholder="SEARCH_QUERY..." />
        <button type="submit" className="terminal-btn">SEARCH</button>
      </form>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {players.map(p => (
          <div key={p.user_id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--terminal-dim)' }}>
            <div>
              <span style={{ color: 'var(--terminal-dim)' }}>ID:</span> {p.username} | 
              <span style={{ marginLeft: 8 }}>{p.display_name}</span>
              <span style={{ marginLeft: 8 }}>
                {p.active_bans > 0
                  ? <span className="badge-banned">BANNED</span>
                  : <span className="badge-online">ACTIVE</span>}
              </span>
            </div>
            <button className="terminal-btn" style={{ color: 'var(--moon-danger)', borderColor: 'var(--moon-danger)', fontSize: '0.7rem' }} onClick={() => ban(p.user_id)}>
              TERMINATE
            </button>
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

  async function save() {
    try {
      await axios.patch(`${API}/admin/mobs/${selected}`,
        { health: +stats.health || undefined, speed: +stats.speed || undefined,
          damage: +stats.damage || undefined, xp_reward: +stats.xp_reward || undefined },
        { headers: authHeader() }
      );
      setMsg('>>> PARAMETERS UPDATED SUCCESSFULLY');
    } catch { setMsg('!!! UPDATE FAILED'); }
    setTimeout(() => setMsg(''), 3000);
  }

  return (
    <section className="terminal-card">
      <div className="terminal-header" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Crosshair size={16} /> Mob_Parameters
      </div>
      <div style={{ display: 'flex', gap: 8, marginBottom: '1rem' }}>
        {mobs.map(m => (
          <button key={m} 
            onClick={() => setSelected(m)}
            style={{ 
              background: selected === m ? 'var(--terminal-green)' : 'transparent',
              color: selected === m ? 'var(--terminal-bg)' : 'var(--terminal-green)',
              border: '1px solid var(--terminal-green)',
              padding: '2px 8px',
              fontSize: '0.8rem',
              cursor: 'pointer'
            }}>
            {m.toUpperCase()}
          </button>
        ))}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: '1rem' }}>
        {(['health','speed','damage','xp_reward'] as const).map(field => (
          <div key={field} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <label style={{ fontSize: '0.7rem', width: 80 }}>{field.toUpperCase()}:</label>
            <input className="terminal-input" type="number"
              value={stats[field]} onChange={e => setStats(s => ({ ...s, [field]: e.target.value }))}
              style={{ width: '100%' }} />
          </div>
        ))}
      </div>
      {msg && <p style={{ color: msg.includes('!!!') ? 'var(--moon-danger)' : 'var(--terminal-green)', marginBottom: 8 }}>{msg}</p>}
      <button className="terminal-btn" onClick={save}>PUSH_CONFIG</button>
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
    <section className="terminal-card">
      <div className="terminal-header" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Activity size={16} /> Global_Broadcast
      </div>
      <div style={{ display: 'flex', gap: 8 }}>
        <span style={{ marginRight: 4 }}>{'>'}</span>
        <input className="terminal-input" value={msg} onChange={e => setMsg(e.target.value)}
          placeholder="ENTER_ANNOUNCEMENT..." />
        <button className="terminal-btn" onClick={send}>SEND</button>
      </div>
    </section>
  );
}

// ─── Dashboard layout ─────────────────────────────────────────────────────────
export default function DashboardPage() {
  const [booting, setBooting] = useState(true);
  const [view, setView] = useState<'status' | 'settings'>('status');

  useEffect(() => {
    if (!localStorage.getItem('moon_token')) window.location.href = '/';
    const timer = setTimeout(() => setBooting(false), 1000);
    return () => clearTimeout(timer);
  }, []);

  function logout() {
    localStorage.removeItem('moon_token');
    localStorage.removeItem('moon_user');
    window.location.href = '/';
  }

  if (booting) {
    return (
      <div style={{ padding: '2rem', color: 'var(--terminal-green)' }}>
        <div>MOON_OS v1.0.4 - SYSTEM BOOT...</div>
        <div>LOADING MODULES: LOBBY_SERVICE, PLAYER_MANAGER, MOB_TUNER...</div>
        <div>[ OK ] AUTH_CHECK</div>
        <div>[ OK ] CONNECT_TO_LOBBY_API</div>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh', padding: '1rem', gap: '1rem' }}>
      {/* Sidebar */}
      <aside style={{ width: 240, borderRight: '1px solid var(--terminal-border)', paddingRight: '1rem', display: 'flex', flexDirection: 'column' }}>
        <div style={{ marginBottom: '2rem', borderBottom: '1px solid var(--terminal-border)', paddingBottom: '1rem' }}>
          <div style={{ fontWeight: 700, fontSize: '1.2rem' }}>MOON_CONTROL_CTR</div>
          <div style={{ fontSize: '0.7rem', color: 'var(--terminal-dim)' }}>SECURE_CONNECTION: ESTABLISHED</div>
        </div>
        
        <nav style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <button className={`terminal-btn ${view === 'status' ? 'active' : ''}`} 
            onClick={() => setView('status')} style={{ textAlign: 'left', fontSize: '0.8rem' }}>
            <Activity size={14} style={{ marginRight: 8 }} /> SYSTEM_STATUS
          </button>
          <button className={`terminal-btn ${view === 'settings' ? 'active' : ''}`}
            onClick={() => setView('settings')} style={{ textAlign: 'left', fontSize: '0.8rem' }}>
            <Settings size={14} style={{ marginRight: 8 }} /> SYSTEM_SETTINGS
          </button>
        </nav>

        <div style={{ flex: 1 }} />
        
        <div style={{ padding: '1rem 0', borderTop: '1px solid var(--terminal-border)' }}>
          <div style={{ fontSize: '0.7rem', marginBottom: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
             <Shield size={12} /> AUTH: SUPER_ADMIN
          </div>
          <button className="terminal-btn" onClick={logout} style={{ width: '100%', fontSize: '0.8rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
            <LogOut size={14} /> LOGOUT_SYSTEM
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main style={{ flex: 1, overflowY: 'auto', paddingRight: '1rem' }}>
        <div style={{ marginBottom: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>{view === 'status' ? 'SYSTEM_DASHBOARD' : 'SECURITY_VAULT'}</h1>
          <div style={{ fontSize: '0.8rem' }}>Uptime: 99.9% | Servers: 04</div>
        </div>

        {view === 'status' ? (
          <>
            <LiveRooms />
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
              <PlayerSearch />
              <MobTuner />
            </div>
            <BroadcastPanel />
          </>
        ) : (
          <SettingsPanel />
        )}
        
        <footer style={{ marginTop: '2rem', fontSize: '0.7rem', color: 'var(--terminal-dim)', textAlign: 'center' }}>
          (c) 2026 MOON_INDUSTRIES // ALL RIGHTS RESERVED
        </footer>
      </main>
    </div>
  );
}

const th: React.CSSProperties = { padding: '8px', fontWeight: 600, fontSize: '0.75rem', color: 'var(--terminal-dim)' };
const td: React.CSSProperties = { padding: '8px', fontSize: '0.85rem' };
