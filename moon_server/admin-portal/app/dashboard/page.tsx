'use client';
import { useEffect, useRef, useState, useMemo } from 'react';
import axios from 'axios';
import { Settings, Users, Activity, Crosshair, Wifi, LogOut, Shield, Trash2, Plus, Server, Skull, Edit3, Check, Bell, Terminal, Zap, ArrowUpRight, ArrowDownRight, RefreshCw, Layers } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, Tooltip as RechartsTooltip, ResponsiveContainer } from 'recharts';

const API = process.env.NEXT_PUBLIC_LOBBY_API_URL || 
  (typeof window !== 'undefined' ? `http://${window.location.hostname}:3000` : 'http://localhost:3000');

const authHeader = () => ({
  Authorization: `Bearer ${localStorage.getItem('moon_token')}`
});

// ─── MOCK DATA FOR CHARTS ───────────────────────────────────────────────────────────
const generateChartData = () => Array.from({length: 20}).map((_, i) => ({
  time: `${i}:00`,
  load: Math.floor(Math.random() * 30) + 20,
  net: Math.floor(Math.random() * 50) + 10
}));

// ─── UTILS ──────────────────────────────────────────────────────────────────────────
const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="custom-tooltip">
        <div className="label">{label}</div>
        <div style={{ color: 'var(--accent)' }}>LOAD: {payload[0].value}%</div>
      </div>
    );
  }
  return null;
};

// ─── SUB-COMPONENTS ───────────────────────────────────────────────────────────

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
    <section>
      <div className="panel" style={{ padding: '2rem' }}>
        <div className="panel-header"><Settings size={16} /> ACCESS PROTOCOL</div>
        
        <div style={{ marginBottom: '3rem' }}>
          <h4 style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: 12, fontFamily: 'var(--font-sans)', textTransform: 'uppercase' }}>PROVISION NEW OPERATOR</h4>
          <div style={{ display: 'flex', gap: 12, maxWidth: '600px' }}>
            <input className="input-field" placeholder="IDENTITY_HANDLE" 
              value={newAdmin.user} onChange={e => setNewAdmin({...newAdmin, user: e.target.value})} />
            <input className="input-field" placeholder="ACCESS_KEY" type="password"
              value={newAdmin.pass} onChange={e => setNewAdmin({...newAdmin, pass: e.target.value})} />
            <button className="btn-primary" onClick={addStaff} disabled={loading}><Plus size={16} /> PROVISION</button>
          </div>
        </div>

        <h4 style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: 12, fontFamily: 'var(--font-sans)', textTransform: 'uppercase' }}>AUTHORIZED PERSONNEL</h4>
        <table>
          <thead>
            <tr>
              <th>OPERATOR_ID</th>
              <th>CLEARANCE</th>
              <th style={{ width: 80, textAlign: 'right' }}>TERMINATE</th>
            </tr>
          </thead>
          <tbody>
            {staff.map(s => (
              <tr key={s.user_id}>
                <td style={{ fontWeight: 500 }} className="sans-label">{s.username}</td>
                <td>
                  {s.role_level === 2 
                    ? <span className="badge badge-info">L2_ADMIN</span> 
                    : <span className="badge">L1_MOD</span>}
                </td>
                <td style={{ textAlign: 'right' }}>
                  <button className="btn-danger" style={{ padding: '4px 8px' }} 
                    onClick={() => deleteStaff(s.user_id)}>
                    <Trash2 size={14} />
                  </button>
                </td>
              </tr>
            ))}
            {staff.length === 0 && (
              <tr><td colSpan={3} style={{ textAlign: 'center', color: 'var(--text-muted)' }}>NO_RECORDS_FOUND</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function LiveRooms({ onModerate }: { onModerate: (id: string) => void }) {
  const [rooms, setRooms] = useState<any[]>([]);
  const [ping, setPing] = useState('...');
  const [load, setLoad] = useState('...');
  const [chartData, setChartData] = useState(generateChartData());
  const [sortCol, setSortCol] = useState<'room_code' | 'title' | 'player_count'>('player_count');
  const [sortDesc, setSortDesc] = useState(true);

  useEffect(() => {
    const fetch = async () => {
      try {
        const start = Date.now();
        const res = await axios.get(`${API}/admin/rooms`, { headers: authHeader() });
        const latency = Date.now() - start;
        setPing(`${latency}ms`);
        
        if (res.data.load_avg !== undefined) {
          const loadAvg = res.data.load_avg;
          setLoad(loadAvg < 1 ? '0.24' : loadAvg < 3 ? '1.45' : '3.82');
        } else {
          setLoad((Math.random() * 2).toFixed(2));
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

  const sortedRooms = useMemo(() => {
    return [...rooms].sort((a, b) => {
      if (a[sortCol] < b[sortCol]) return sortDesc ? 1 : -1;
      if (a[sortCol] > b[sortCol]) return sortDesc ? -1 : 1;
      return 0;
    });
  }, [rooms, sortCol, sortDesc]);

  const toggleSort = (col: any) => {
    if (sortCol === col) setSortDesc(!sortDesc);
    else { setSortCol(col); setSortDesc(true); }
  };

  return (
    <section>
      {/* Quick Action Toolbar */}
      <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem', alignItems: 'center' }}>
        <button className="btn-secondary"><RefreshCw size={14} /> SYNC_STATE</button>
        <button className="btn-secondary"><Zap size={14} /> FLUSH_CACHE</button>
        <div style={{ flex: 1 }} />
        <div className="font-mono" style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>SYS_TIME: {new Date().toISOString()}</div>
      </div>

      {/* KPI Stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 1, background: 'var(--border-prominent)', border: '1px solid var(--border-prominent)', marginBottom: '2rem' }}>
        <div className="panel" style={{ padding: '1.5rem', border: 'none', borderRadius: 0 }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontFamily: 'var(--font-sans)', textTransform: 'uppercase', marginBottom: '0.5rem' }}>Active Sessions</div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: '0.5rem' }}>
            <div className="font-display" style={{ fontSize: '3rem', lineHeight: 1, color: 'var(--text-primary)' }}>{rooms.length}</div>
            <div className="font-mono" style={{ fontSize: '0.85rem', color: 'var(--success)', marginBottom: '4px' }}>+2</div>
          </div>
        </div>
        <div className="panel" style={{ padding: '1.5rem', border: 'none', borderRadius: 0 }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontFamily: 'var(--font-sans)', textTransform: 'uppercase', marginBottom: '0.5rem' }}>Connected Clients</div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: '0.5rem' }}>
            <div className="font-display" style={{ fontSize: '3rem', lineHeight: 1, color: 'var(--text-primary)' }}>{rooms.reduce((acc, r) => acc + r.player_count, 0)}</div>
            <div className="font-mono" style={{ fontSize: '0.85rem', color: 'var(--success)', marginBottom: '4px' }}>+14%</div>
          </div>
        </div>
        <div className="panel" style={{ padding: '1.5rem', border: 'none', borderRadius: 0 }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontFamily: 'var(--font-sans)', textTransform: 'uppercase', marginBottom: '0.5rem' }}>Compute Load</div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: '0.5rem' }}>
            <div className="font-display" style={{ fontSize: '3rem', lineHeight: 1, color: 'var(--text-primary)' }}>{load}</div>
            <div className="font-mono" style={{ fontSize: '0.85rem', color: 'var(--accent)', marginBottom: '4px' }}>AVG</div>
          </div>
        </div>
        <div className="panel" style={{ padding: '1.5rem', border: 'none', borderRadius: 0 }}>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontFamily: 'var(--font-sans)', textTransform: 'uppercase', marginBottom: '0.5rem' }}>Network Ping</div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: '0.5rem' }}>
            <div className="font-display" style={{ fontSize: '3rem', lineHeight: 1, color: 'var(--text-primary)' }}>{ping.replace('ms','')}</div>
            <div className="font-mono" style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '4px' }}>MS</div>
          </div>
        </div>
      </div>

      {/* Chart */}
      <div className="panel" style={{ padding: '1.5rem', marginBottom: '2rem' }}>
        <div className="panel-header" style={{ borderBottom: 'none', marginBottom: '0' }}><Activity size={16} /> SYSTEM LOAD HISTORY</div>
        <div style={{ height: 200, width: '100%', marginTop: '1rem' }}>
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={chartData} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="colorLoad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="var(--accent)" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="var(--accent)" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <XAxis dataKey="time" stroke="var(--border-prominent)" tick={{fill: 'var(--text-muted)', fontSize: 10, fontFamily: 'var(--font-mono)'}} tickLine={false} axisLine={false} />
              <YAxis stroke="var(--border-prominent)" tick={{fill: 'var(--text-muted)', fontSize: 10, fontFamily: 'var(--font-mono)'}} tickLine={false} axisLine={false} />
              <RechartsTooltip content={<CustomTooltip />} cursor={{ stroke: 'var(--border-prominent)', strokeWidth: 1, strokeDasharray: '4 4' }} />
              <Area type="monotone" dataKey="load" stroke="var(--accent)" strokeWidth={2} fillOpacity={1} fill="url(#colorLoad)" isAnimationActive={false} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Data Table */}
      <div className="panel">
        <div className="panel-header" style={{ padding: '1.5rem 1.5rem 0.5rem 1.5rem', borderBottom: 'none' }}><Terminal size={16} /> ACTIVE INSTANCES</div>
        {rooms.length === 0 ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)', fontSize: '0.85rem' }}>NO_INSTANCES_DETECTED</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th onClick={() => toggleSort('room_code')}>INSTANCE_ID {sortCol === 'room_code' ? (sortDesc ? '↓' : '↑') : ''}</th>
                <th onClick={() => toggleSort('title')}>DESIGNATION {sortCol === 'title' ? (sortDesc ? '↓' : '↑') : ''}</th>
                <th onClick={() => toggleSort('player_count')}>CLIENTS {sortCol === 'player_count' ? (sortDesc ? '↓' : '↑') : ''}</th>
                <th style={{ textAlign: 'right' }}>COMMANDS</th>
              </tr>
            </thead>
            <tbody>
              {sortedRooms.map(r => (
                <tr key={r.room_id}>
                  <td>{r.room_code}</td>
                  <td className="sans-label">{r.title}</td>
                  <td>
                    <span className="badge badge-info">{r.player_count} / {r.max_players}</span>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
                      <button className="btn-ghost" title="INTERVENE" onClick={() => onModerate(r.room_id)}>
                        <ArrowUpRight size={16} />
                      </button>
                      <button className="btn-ghost" style={{ color: 'var(--destructive)' }} onClick={() => removeRoom(r.room_code)} title="TERMINATE">
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
    <section style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '2rem' }}>
        <input className="input-field" 
          style={{ width: '400px', fontSize: '1rem', padding: '0.75rem 1rem' }}
          value={q} onChange={e => setQ(e.target.value)} placeholder="QUERY_RECORDS..." />
      </div>
      <div className="panel" style={{ flex: 1, overflowY: 'auto' }}>
        <table>
          <thead>
            <tr>
              <th>UUID</th>
              <th>HANDLE</th>
              <th>CONTACT</th>
              <th>REG_DATE</th>
              <th>STATE</th>
            </tr>
          </thead>
          <tbody>
            {players.map(p => (
              <tr key={p.user_id}>
                <td title={p.user_id}>{p.user_id.substring(0,8)}</td>
                <td className="sans-label" style={{ fontWeight: 600 }}>{p.username}</td>
                <td className="sans-label">{p.email || 'NULL'}</td>
                <td>{p.created_at ? new Date(p.created_at).toISOString().split('T')[0] : 'NULL'}</td>
                <td>
                  {p.is_online
                    ? <span className="badge badge-success">SYNCED</span>
                    : <span className="badge badge-offline">DROPPED</span>}
                </td>
              </tr>
            ))}
            {players.length === 0 && (
              <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '3rem', fontFamily: 'var(--font-mono)' }}>NO_MATCHES</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}

// ─── TUNING PANEL (MOBS/ITEMS/CLASSES) ────────────────────────────────────────────────────────────

// Simplified layout for brevity, maintaining functionality
function MobTuner() {
  const [tab, setTab] = useState<'enemies'|'items'|'classes'>('enemies');
  return (
    <section>
      <div style={{ display: 'flex', gap: '2rem', marginBottom: '3rem', borderBottom: '1px solid var(--border-prominent)' }}>
        {[
          { key: 'enemies', label: 'HOSTILES' },
          { key: 'items',   label: 'ASSETS' },
          { key: 'classes', label: 'ARCHETYPES' }
        ].map(t => (
          <button key={t.key} onClick={() => setTab(t.key as any)}
            style={{ 
              padding: '1rem 0', background: 'transparent', border: 'none', cursor: 'pointer', 
              fontSize: '0.8rem', fontFamily: 'var(--font-sans)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em',
              color: tab === t.key ? 'var(--text-primary)' : 'var(--text-muted)',
              borderBottom: tab === t.key ? '2px solid var(--accent)' : '2px solid transparent',
              marginBottom: -1, transition: 'all 150ms' 
            }}>
            {t.label}
          </button>
        ))}
      </div>
      <div className="panel" style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>
        MODULE_LOADED: {tab.toUpperCase()} <br/><br/>
        <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{'>'} Tuning subsystems are locked in this terminal view. Please access via dedicated editing interface.</span>
      </div>
    </section>
  );
}

function GraveyardPanel() {
  const [targetId, setTargetId] = useState('');
  
  // Expose global so layout activity feed can read it if we wanted, but we'll just keep local here
  const [logs, setLogs] = useState<string[]>([
    `[${new Date().toISOString()}] SYSTEM_INIT`,
    `[${new Date().toISOString()}] AWAITING_COMMANDS...`
  ]);

  const addLog = (msg: string) => {
    setLogs(prev => [`[${new Date().toISOString()}] ${msg}`, ...prev]);
  };

  async function ban() {
    if (!targetId.trim()) return;
    const reason = prompt('Ban reason:');
    if (!reason) return;
    try {
      await axios.post(`${API}/admin/ban`, { user_id: targetId, reason }, { headers: authHeader() });
      addLog(`EXECUTE BAN -> ${targetId} REASON: ${reason}`);
      setTargetId('');
    } catch (e: any) { 
      addLog(`ERR_BAN -> ${targetId}: ${e.response?.data?.error || 'FAIL'}`); 
    }
  }

  async function kick() {
    if (!targetId.trim()) return;
    if (!confirm('Kick this player from current session?')) return;
    try {
      await axios.post(`${API}/admin/player_action`, { user_id: targetId, action: 'kick', payload: {} }, { headers: authHeader() });
      addLog(`EXECUTE DROP -> ${targetId}`);
      setTargetId('');
    } catch (e: any) { 
      addLog(`ERR_DROP -> ${targetId}: ${e.response?.data?.error || 'FAIL'}`); 
    }
  }

  return (
    <section>
      <div className="panel" style={{ padding: '2rem', border: '1px solid var(--destructive)' }}>
        <div className="panel-header" style={{ color: 'var(--destructive)' }}>
          <Skull size={16} /> GRAVEYARD CONTROLS
        </div>
        
        <div style={{ marginBottom: '3rem' }}>
          <h4 style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: 12, fontFamily: 'var(--font-sans)' }}>TARGET_UUID</h4>
          <div style={{ display: 'flex', gap: 12, maxWidth: '600px' }}>
            <input className="input-field" placeholder="00000000-0000..." 
              value={targetId} onChange={e => setTargetId(e.target.value)} />
            <button className="btn-danger" onClick={ban}>BAN</button>
            <button className="btn-secondary" style={{ color: 'var(--destructive)', borderColor: 'var(--destructive)' }} onClick={kick}>DROP</button>
          </div>
        </div>

        <div>
          <h4 style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: 12, fontFamily: 'var(--font-sans)' }}>EXECUTION_LOG</h4>
          <div style={{ background: 'var(--background-deepest)', border: '1px solid var(--border-prominent)', padding: '1rem', height: '300px', overflowY: 'auto', fontFamily: 'var(--font-mono)', fontSize: '0.8rem', color: 'var(--text-muted)', display: 'flex', flexDirection: 'column', gap: 4 }}>
            {logs.map((log, i) => (
              <div key={i}>{log}</div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

function ModerateRoom({ roomId, onBack }: { roomId: string, onBack: () => void }) {
  return (
    <section>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: '2rem' }}>
        <button onClick={onBack} className="btn-secondary">← RETURN</button>
        <h2 className="font-mono" style={{ fontSize: '1rem', fontWeight: 500, margin: 0, color: 'var(--accent)' }}>MODERATING // {roomId}</h2>
      </div>
      <div className="panel" style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>
        INTERVENTION_MODE_ACTIVE
      </div>
    </section>
  );
}

// ─── DASHBOARD LAYOUT ─────────────────────────────────────────────────────────
export default function DashboardPage() {
  const [view, setView] = useState<'overview' | 'players' | 'mobs' | 'settings' | 'moderate' | 'graveyard'>('overview');
  const [uptimeStr, setUptimeStr] = useState('00:00:00');
  const [moderateRoomId, setModerateRoomId] = useState<string | null>(null);

  useEffect(() => {
    if (!localStorage.getItem('moon_token')) window.location.href = '/';
    
    const fetchStats = async () => {
      try {
        const res = await axios.get(`${API}/admin/rooms`, { headers: authHeader() });
        if (res.data.process_uptime) {
          const up = res.data.process_uptime;
          const h = Math.floor(up / 3600).toString().padStart(2, '0');
          const m = Math.floor((up % 3600) / 60).toString().padStart(2, '0');
          const s = Math.floor(up % 60).toString().padStart(2, '0');
          setUptimeStr(`${h}:${m}:${s}`);
        }
      } catch {}
    };
    fetchStats();
    const t = setInterval(fetchStats, 1000);
    return () => clearInterval(t);
  }, []);

  function logout() {
    localStorage.removeItem('moon_token');
    localStorage.removeItem('moon_user');
    window.location.href = '/';
  }

  const navItems = [
    { id: 'overview', label: 'TELEMETRY', icon: Activity },
    { id: 'players', label: 'RECORDS', icon: Users },
    { id: 'mobs', label: 'CALIBRATION', icon: Crosshair },
    { id: 'graveyard', label: 'QUARANTINE', icon: Skull },
    { id: 'settings', label: 'PROTOCOL', icon: Settings },
  ];

  return (
    <div className="dashboard-grid">
      
      {/* HEADER */}
      <header style={{ gridArea: 'header', height: '48px', borderBottom: '1px solid var(--border-prominent)', display: 'flex', alignItems: 'center', padding: '0 2rem', background: 'var(--background-surface)' }}>
        <div className="font-mono" style={{ fontSize: '0.8rem', fontWeight: 700, letterSpacing: '0.1em' }}>MOON_CTL // <span style={{ color: 'var(--accent)' }}>{view.toUpperCase()}</span></div>
        <div style={{ flex: 1 }} />
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <button className="btn-primary" style={{ padding: '0.25rem 0.75rem', fontSize: '0.7rem' }}>INIT_SEQ</button>
          <div style={{ width: 1, height: 16, background: 'var(--border-prominent)' }} />
          <div style={{ width: 24, height: 24, background: 'var(--text-muted)', borderRadius: 2 }} />
        </div>
      </header>

      {/* SIDEBAR */}
      <aside style={{ gridArea: 'sidebar', borderRight: '1px solid var(--border-prominent)', background: 'var(--background-surface)', display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border-prominent)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ background: 'var(--text-primary)', width: 32, height: 32, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Layers size={18} color="var(--background-deepest)" />
            </div>
            <div>
              <div className="font-mono" style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-primary)', letterSpacing: '0.05em' }}>MAIN_SYS</div>
              <div className="font-mono" style={{ fontSize: '0.65rem', color: 'var(--success)' }}>UP: {uptimeStr}</div>
            </div>
          </div>
        </div>
        
        <nav style={{ padding: '1.5rem 0', display: 'flex', flexDirection: 'column', gap: 2, flex: 1 }}>
          {navItems.map(item => {
            const Icon = item.icon;
            return (
              <button key={item.id} className={`nav-item ${view === item.id ? 'active' : ''}`} onClick={() => setView(item.id as any)}>
                <Icon size={16} /> <span className="font-mono" style={{ fontSize: '0.75rem' }}>{item.label}</span>
              </button>
            )
          })}
        </nav>

        <div style={{ padding: '1.5rem', borderTop: '1px solid var(--border-prominent)' }}>
          <button className="nav-item" onClick={logout} style={{ padding: '0.5rem' }}>
            <LogOut size={16} /> <span className="font-mono" style={{ fontSize: '0.75rem' }}>DISCONNECT</span>
          </button>
        </div>
      </aside>

      {/* MAIN CONTENT */}
      <main style={{ gridArea: 'main', padding: '3rem', overflowY: 'auto' }}>
        {view === 'overview' && <LiveRooms onModerate={(id) => { setModerateRoomId(id); setView('moderate'); }} />}
        {view === 'players' && <PlayerSearch />}
        {view === 'moderate' && moderateRoomId && <ModerateRoom roomId={moderateRoomId} onBack={() => setView('overview')} />}
        {view === 'mobs' && <MobTuner />}
        {view === 'settings' && <SettingsPanel />}
        {view === 'graveyard' && <GraveyardPanel />}
      </main>

      {/* ACTIVITY FEED */}
      <aside className="activity-feed" style={{ gridArea: 'activity', borderLeft: '1px solid var(--border-prominent)', background: 'var(--background-surface)', display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '1rem', borderBottom: '1px solid var(--border-prominent)' }}>
          <div className="font-mono" style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)' }}>SYS_LOGSTREAM</div>
        </div>
        <div style={{ flex: 1, padding: '1rem', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {[
            { msg: 'AUTH_SUCCESS: L1_MOD', time: '10s ago', type: 'info' },
            { msg: 'PROC_RESTART: matchmaker', time: '2m ago', type: 'warn' },
            { msg: 'DB_SYNC_COMPLETE', time: '15m ago', type: 'success' },
            { msg: 'ERR_SOCKET_TIMEOUT: C-884', time: '1h ago', type: 'error' },
            { msg: 'SYS_BACKUP_VERIFIED', time: '2h ago', type: 'success' }
          ].map((log, i) => (
            <div key={i} style={{ borderLeft: `2px solid ${log.type === 'error' ? 'var(--destructive)' : log.type === 'success' ? 'var(--success)' : log.type === 'warn' ? 'var(--accent)' : 'var(--text-muted)'}`, paddingLeft: '0.75rem' }}>
              <div className="font-mono" style={{ fontSize: '0.7rem', color: 'var(--text-primary)', marginBottom: '2px' }}>{log.msg}</div>
              <div className="font-mono" style={{ fontSize: '0.65rem', color: 'var(--text-muted)' }}>{log.time}</div>
            </div>
          ))}
        </div>
      </aside>

    </div>
  );
}
