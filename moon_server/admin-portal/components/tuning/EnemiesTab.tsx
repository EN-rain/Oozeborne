'use client';
import { useState, useEffect } from 'react';
import { Edit3, Check, Plus, X, Shield, Zap, Target, Coins, TrendingUp } from 'lucide-react';
import { api } from '../../lib/api';

const MOB_GROUPS = [
  { key: 'common', label: 'Common Mobs', color: 'var(--success)', mobs: ['slime'] },
  { key: 'elite', label: 'Elite Mobs', color: 'var(--warning)', mobs: ['lancer', 'archer'] },
  { key: 'boss', label: 'Boss Entities', color: 'var(--danger)', mobs: ['warden'] },
];

function MobEditor({ mobType, onBack }: { mobType: string; onBack: () => void }) {
  const [stats, setStats] = useState<any>({ attributes: {}, skills: [] });
  const [msg, setMsg] = useState('');

  useEffect(() => {
    api.getMob(mobType).then(res => {
      if (res.mob) {
        setStats({
          ...res.mob,
          attributes: res.mob.attributes || {},
          skills: res.mob.skills || []
        });
      }
    });
  }, [mobType]);

  async function save() {
    try {
      await api.updateMob(mobType, stats);
      setMsg('Configuration Saved');
      setTimeout(() => setMsg(''), 2000);
    } catch { 
      setMsg('Sync Error');
      setTimeout(() => setMsg(''), 3000);
    }
  }

  const getLabel = (f: string) => {
    if (f === 'xp_reward') return 'XP';
    if (f === 'gold_reward') return 'GOLD';
    return f.replace(/_/g, ' ').toUpperCase();
  };

  const StatField = ({ label, sublabel, value, onChange, type = "number", step = "1" }: any) => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
        <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--text-muted)', letterSpacing: '0.05em' }}>{label}</span>
        <span style={{ fontSize: '0.55rem', fontWeight: 600, color: 'var(--accent-primary)', opacity: 0.8 }}>{sublabel}</span>
      </div>
      <input 
        className="input-field"
        type={type}
        step={step}
        value={value ?? ''}
        onChange={e => onChange(type === "number" ? parseFloat(e.target.value) : e.target.value)}
        style={{ 
          fontSize: '0.9rem', 
          height: '34px', 
          background: 'rgba(255,255,255,0.03)',
          border: '1px solid rgba(255,255,255,0.1)',
          padding: '0 10px',
          fontWeight: 600,
          color: 'var(--text-main)'
        }}
      />
    </div>
  );

  return (
    <div style={{ 
      display: 'flex', flexDirection: 'column', height: '100%', 
      background: 'var(--bg-main)', border: '1px solid var(--border-light)', 
      boxShadow: '0 0 40px rgba(0,0,0,0.5)', overflow: 'hidden' 
    }}>
      {/* Header */}
      <div style={{ 
        padding: '1rem 1.5rem', borderBottom: '1px solid var(--border-light)', 
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        background: 'rgba(255,255,255,0.02)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 15 }}>
          <button onClick={onBack} style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', display: 'flex' }}>
            <X size={20} />
          </button>
          <div style={{ height: 24, width: 1, background: 'var(--border-light)' }} />
          <div>
            <h2 style={{ fontSize: '1.2rem', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.1em', margin: 0, display: 'flex', alignItems: 'center', gap: 10 }}>
              {mobType} <span style={{ fontSize: '0.7rem', opacity: 0.5 }}>CONFIGURATION</span>
            </h2>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
          {msg && <span style={{ fontSize: '0.8rem', fontWeight: 700, color: msg.includes('Error') ? 'var(--danger)' : 'var(--accent-primary)' }}>{msg}</span>}
          <button className="btn-primary" onClick={save} style={{ padding: '8px 24px', fontWeight: 800, fontSize: '0.8rem' }}>
            DEPLOY CHANGES
          </button>
        </div>
      </div>

      {/* Main Content Split */}
      <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        {/* Left Column: Stats */}
        <div className="no-scrollbar" style={{ flex: '0 0 450px', padding: '1.5rem', borderRight: '1px solid var(--border-light)', overflowY: 'auto' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
            
            {/* Core Stats Group */}
            <section>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12, color: 'var(--success)' }}>
                <Shield size={14} />
                <span style={{ fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Core Statistics</span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <StatField label="HEALTH" sublabel="points" value={stats.health} onChange={(v:any) => setStats({...stats, health: v})} />
                <StatField label="SPEED" sublabel="units/sec" value={stats.speed} onChange={(v:any) => setStats({...stats, speed: v})} />
                <StatField label="ATTACK" sublabel="damage" value={stats.damage} onChange={(v:any) => setStats({...stats, damage: v})} />
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
                    <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--text-muted)', letterSpacing: '0.05em' }}>CATEGORY</span>
                  </div>
                  <select className="input-field" 
                    style={{ fontSize: '0.9rem', height: '34px', background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.1)', padding: '0 10px', fontWeight: 600, color: 'var(--text-main)' }}
                    value={stats.category || 'common'} onChange={e => setStats({ ...stats, category: e.target.value })}>
                    <option value="common">Common</option>
                    <option value="elite">Elite</option>
                    <option value="boss">Boss</option>
                  </select>
                </div>
              </div>
            </section>

            {/* Rewards Group */}
            <section>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12, color: 'var(--warning)' }}>
                <Coins size={14} />
                <span style={{ fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Rewards & Progression</span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <StatField label="XP REWARD" sublabel="base" value={stats.xp_reward} onChange={(v:any) => setStats({...stats, xp_reward: v})} />
                <StatField label="GOLD REWARD" sublabel="base" value={stats.gold_reward} onChange={(v:any) => setStats({...stats, gold_reward: v})} />
              </div>
            </section>

            {/* Advanced Mechanics (JSONB Attributes) */}
            <section>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12, color: 'var(--accent-primary)' }}>
                <Zap size={14} />
                <span style={{ fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Advanced Mechanics</span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                {Object.keys(stats.attributes).map(key => (
                  <div key={key} style={{ position: 'relative' }}>
                    <StatField label={getLabel(key)} sublabel="dynamic" value={stats.attributes[key]} step="any"
                      onChange={(v:any) => setStats({ ...stats, attributes: { ...stats.attributes, [key]: v } })} />
                    <button onClick={() => {
                        const newAttrs = { ...stats.attributes };
                        delete newAttrs[key];
                        setStats({ ...stats, attributes: newAttrs });
                      }}
                      style={{ position: 'absolute', top: 0, right: 0, background: 'transparent', border: 'none', color: 'var(--danger)', cursor: 'pointer', padding: 0 }}>
                      <X size={12} />
                    </button>
                  </div>
                ))}
                
                {/* Add new attribute button */}
                <button onClick={() => {
                    const key = prompt("Attribute name (e.g. attack_speed):");
                    if (key) setStats({ ...stats, attributes: { ...stats.attributes, [key]: 1.0 } });
                  }}
                  style={{ 
                    height: 34, border: '1px dashed rgba(255,255,255,0.2)', background: 'transparent', 
                    color: 'var(--text-muted)', fontSize: '0.7rem', fontWeight: 700, cursor: 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, marginTop: 17
                  }}>
                  <Plus size={12} /> ADD ATTRIBUTE
                </button>
              </div>
            </section>

          </div>
        </div>

        {/* Right Column: Skills */}
        <div className="no-scrollbar" style={{ flex: 1, padding: '1.5rem', overflowY: 'auto', background: 'rgba(0,0,0,0.1)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16, color: 'var(--danger)' }}>
            <Target size={14} />
            <span style={{ fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Ability Set & Behaviors</span>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 15 }}>
            {stats.skills.map((sk: any, idx: number) => (
              <div key={idx} className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--accent-primary)', position: 'relative' }}>
                <button onClick={() => {
                  const newSkills = stats.skills.filter((_: any, i: number) => i !== idx);
                  setStats({...stats, skills: newSkills});
                }} style={{ position: 'absolute', top: 10, right: 10, background: 'transparent', border: 'none', color: 'var(--danger)', cursor: 'pointer' }}>
                  <X size={16} />
                </button>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                  <div>
                    <label style={{ fontSize: '0.6rem', fontWeight: 800, color: 'var(--text-muted)', display: 'block', marginBottom: 4 }}>SKILL NAME</label>
                    <input className="input-field" value={sk.name} onChange={e => {
                      const newSkills = [...stats.skills];
                      newSkills[idx].name = e.target.value;
                      setStats({...stats, skills: newSkills});
                    }} style={{ fontWeight: 800, fontSize: '0.9rem' }} />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.6rem', fontWeight: 800, color: 'var(--text-muted)', display: 'block', marginBottom: 4 }}>DESCRIPTION & STATS</label>
                    <textarea className="input-field" value={sk.desc} onChange={e => {
                      const newSkills = [...stats.skills];
                      newSkills[idx].desc = e.target.value;
                      setStats({...stats, skills: newSkills});
                    }} style={{ fontSize: '0.8rem', minHeight: '80px', lineHeight: 1.5, fontFamily: 'monospace' }} />
                  </div>
                </div>
              </div>
            ))}

            <button onClick={() => setStats({...stats, skills: [...stats.skills, {name: 'New Ability', desc: 'Description here...'}]})}
              style={{ 
                minHeight: 150, border: '2px dashed rgba(255,255,255,0.1)', background: 'transparent', 
                color: 'var(--text-muted)', fontSize: '0.8rem', fontWeight: 800, cursor: 'pointer',
                display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 10,
                borderRadius: 8
              }}>
              <Plus size={24} /> ADD ABILITY
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function MobCard({ mobType, onClick }: { mobType: string; onClick: () => void }) {
  const group = MOB_GROUPS.find(g => g.mobs.includes(mobType));

  return (
    <button onClick={onClick} className="glass-card" 
      style={{ 
        padding: '1.25rem', background: 'rgba(0,0,0,0.3)', position: 'relative', cursor: 'pointer', border: '1px solid rgba(255,255,255,0.05)', textAlign: 'left', width: '100%',
        transition: 'all 0.2s', display: 'flex', flexDirection: 'column', gap: 10
      }}
      onMouseOver={e => { e.currentTarget.style.borderColor = 'var(--accent-primary)'; e.currentTarget.style.background = 'rgba(255,255,255,0.05)'; }}
      onMouseOut={e => { e.currentTarget.style.borderColor = 'rgba(255,255,255,0.05)'; e.currentTarget.style.background = 'rgba(0,0,0,0.3)'; }}>
      
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h3 style={{ fontSize: '1rem', fontWeight: 900, color: 'var(--text-main)', textTransform: 'uppercase', letterSpacing: '0.05em', margin: 0 }}>{mobType}</h3>
        <TrendingUp size={14} style={{ color: group?.color || 'var(--text-muted)', opacity: 0.5 }} />
      </div>
      
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <div style={{ width: 8, height: 8, borderRadius: '50%', background: group?.color || 'var(--text-muted)' }} />
        <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)', fontWeight: 800, textTransform: 'uppercase' }}>{group?.key || 'Standard'}</span>
      </div>
    </button>
  );
}

export default function EnemiesTab({ search }: { search: string }) {
  const [selectedMob, setSelectedMob] = useState<string | null>(null);

  const bossMobs = MOB_GROUPS.find(g => g.key === 'boss')?.mobs || [];
  const eliteMobs = MOB_GROUPS.find(g => g.key === 'elite')?.mobs || [];
  const commonMobs = MOB_GROUPS.find(g => g.key === 'common')?.mobs || [];
  const allMobs = [...bossMobs, ...eliteMobs, ...commonMobs];

  const filtered = allMobs.filter(m => 
    m.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div style={{ height: '100%' }}>
      {selectedMob ? (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 1000, padding: 0 }}>
          <MobEditor 
            mobType={selectedMob} 
            onBack={() => setSelectedMob(null)} 
          />
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 12 }}>
          {filtered.map(m => <MobCard key={m} mobType={m} onClick={() => setSelectedMob(m)} />)}
          {filtered.length === 0 && (
            <div style={{ textAlign: 'center', padding: '5rem', color: 'var(--text-muted)', gridColumn: '1 / -1', border: '1px dashed rgba(255,255,255,0.1)', borderRadius: 12 }}>
              <Target size={40} style={{ opacity: 0.2, marginBottom: 15 }} />
              <div style={{ fontWeight: 800, fontSize: '0.9rem', opacity: 0.5 }}>NO TARGETS ACQUIRED</div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
