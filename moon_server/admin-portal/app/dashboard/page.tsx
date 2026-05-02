'use client';
import { useEffect, useState } from 'react';
import { Settings, Users, Activity, Crosshair, LogOut, Skull } from 'lucide-react';
import { api } from '../../lib/api';

import SettingsPanel from '../../components/SettingsPanel';
import LiveRooms from '../../components/LiveRooms';
import PlayerSearch from '../../components/PlayerSearch';
import PlayerDetailModal from '../../components/PlayerDetailModal';
import GraveyardPanel from '../../components/GraveyardPanel';
import ModerateRoom from '../../components/ModerateRoom';
import MobTuner from '../../components/MobTuner';

export default function DashboardPage() {
  const [view, setView] = useState<'overview' | 'players' | 'mobs' | 'broadcast' | 'settings' | 'moderate' | 'graveyard'>('overview');
  const [roomsCount, setRoomsCount] = useState(0);
  const [uptimeStr, setUptimeStr] = useState('Checking...');
  const [moderateRoomId, setModerateRoomId] = useState<string | null>(null);
  const [selectedPlayerId, setSelectedPlayerId] = useState<string | null>(null);

  useEffect(() => {
    if (!localStorage.getItem('moon_token')) window.location.href = '/';
    
    const fetchStats = async () => {
      try {
        const res = await api.getRooms();
        setRoomsCount(res.rooms?.length || 0);
        
        if (res.process_uptime) {
          const up = res.process_uptime;
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

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <aside style={{ position: 'fixed', top: 0, left: 0, bottom: 0, width: 260, borderRight: '1px solid var(--border-light)', background: 'var(--bg-card)', display: 'flex', flexDirection: 'column', padding: '2rem 1.5rem', zIndex: 50 }}>
        <div style={{ marginBottom: '3rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <div style={{ fontWeight: 800, fontSize: '0.9rem', letterSpacing: '0.05em', color: 'var(--text-main)', textTransform: 'uppercase' }}>MOON SERVER</div>
            <div style={{ fontSize: '0.7rem', color: 'var(--accent-primary)', fontWeight: 600 }}>Uptime: {uptimeStr}</div>
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
            <Crosshair size={18} /> Tuning
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
        {view === 'players' && <PlayerSearch onSelectPlayer={setSelectedPlayerId} />}
        {view === 'moderate' && moderateRoomId && <ModerateRoom roomId={moderateRoomId} onBack={() => setView('overview')} onSelectPlayer={setSelectedPlayerId} />}
        {view === 'mobs' && <MobTuner />}
        {view === 'settings' && <SettingsPanel />}
        {view === 'graveyard' && <GraveyardPanel />}

        {selectedPlayerId && <PlayerDetailModal userId={selectedPlayerId} onClose={() => setSelectedPlayerId(null)} />}
      </main>
    </div>
  );
}
