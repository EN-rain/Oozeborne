'use client';
import { useState, useEffect } from 'react';
import { Edit3, Check, Plus } from 'lucide-react';
import { api } from '../../lib/api';

const MOB_GROUPS = [
  { key: 'common', label: 'Common Mobs', color: 'var(--success)', mobs: ['slime'] },
  { key: 'elite', label: 'Elite Mobs', color: 'var(--warning)', mobs: ['lancer', 'archer'] },
  { key: 'boss', label: 'Boss Entities', color: 'var(--danger)', mobs: ['warden'] },
];

function MobDetailPage({ mobType, onBack }: { mobType: string; onBack: () => void }) {
  const [stats, setStats] = useState<any>({ attributes: {}, skills: [] });
  const [isEditing, setIsEditing] = useState(false);
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
      setMsg('Saved');
      setIsEditing(false);
    } catch { setMsg('Error'); }
    setTimeout(() => setMsg(''), 2000);
  }

  const coreFields = ['health', 'speed', 'damage', 'xp_reward', 'gold_reward', 'category'];

  const getLabel = (f: string) => {
    if (f === 'damage') return 'Attack';
    if (f === 'xp_reward') return 'XP Reward';
    if (f === 'gold_reward') return 'Gold Reward';
    if (f === 'phase_2_threshold') return 'Phase 2 (%)';
    if (f === 'phase_3_threshold') return 'Phase 3 (%)';
    return f.replace(/_/g, ' ');
  };

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: '1.5rem' }}>
        <button onClick={onBack} className="btn-outline" style={{ padding: '6px 12px' }}>← Back</button>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <h2 style={{ fontSize: '1.1rem', fontWeight: 800, textTransform: 'capitalize', margin: 0, color: 'var(--text-main)' }}>{mobType}</h2>
          {msg && <span style={{ fontSize: '0.8rem', color: msg === 'Error' ? 'var(--danger)' : 'var(--success)', marginLeft: 10 }}>{msg}</span>}
        </div>
        <div style={{ flex: 1 }} />
        <button className="btn-outline" onClick={() => { if (isEditing) save(); setIsEditing(!isEditing); }}
          style={{ background: isEditing ? 'rgba(255,255,255,0.1)' : 'transparent', color: 'var(--text-main)', border: isEditing ? '1px solid var(--text-main)' : '1px solid var(--border-light)', padding: '10px' }}
          title={isEditing ? 'Confirm' : 'Edit Stats'}>
          {isEditing ? <Check size={18} /> : <Edit3 size={18} />}
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div className="glass-card" style={{ padding: '1rem' }}>
            <div className="glass-header" style={{ color: 'var(--text-main)', opacity: 0.9, marginBottom: '0.8rem' }}>Base Stats</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {coreFields.map(f => (
                <div key={f}>
                  <label style={{ fontSize: '0.6rem', color: 'var(--text-muted)', display: 'block', marginBottom: 2, textTransform: 'uppercase', fontWeight: 700 }}>
                    {getLabel(f)}
                  </label>
                  {f === 'category' ? (
                    <select className="input-field" disabled={!isEditing}
                      style={{ padding: '4px 8px', fontSize: '0.8rem', height: '30px', background: isEditing ? 'var(--bg-input)' : 'transparent', borderColor: isEditing ? 'var(--border-light)' : 'transparent' }}
                      value={stats[f] || 'common'} onChange={e => setStats({ ...stats, [f]: e.target.value })}>
                      <option value="common">Common</option>
                      <option value="elite">Elite</option>
                      <option value="boss">Boss</option>
                    </select>
                  ) : (
                    <input className="input-field" type="number" disabled={!isEditing}
                      style={{ padding: '4px 8px', fontSize: '0.8rem', height: '30px', background: isEditing ? 'var(--bg-input)' : 'transparent', borderColor: isEditing ? 'var(--border-light)' : 'transparent' }}
                      value={stats[f] || 0} onChange={e => setStats({ ...stats, [f]: +e.target.value })} />
                  )}
                </div>
              ))}
            </div>
          </div>

          {Object.keys(stats.attributes).length > 0 && (
            <div className="glass-card" style={{ padding: '1rem' }}>
              <div className="glass-header" style={{ color: 'var(--text-main)', opacity: 0.9, marginBottom: '0.8rem' }}>Advanced Mechanics</div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                {Object.keys(stats.attributes).map(key => (
                  <div key={key}>
                    <label style={{ fontSize: '0.6rem', color: 'var(--text-muted)', display: 'block', marginBottom: 2, textTransform: 'uppercase', fontWeight: 700 }}>
                      {getLabel(key)}
                    </label>
                    <input className="input-field" type="number" step="any" disabled={!isEditing}
                      style={{ padding: '4px 8px', fontSize: '0.8rem', height: '30px', background: isEditing ? 'var(--bg-input)' : 'transparent', borderColor: isEditing ? 'var(--border-light)' : 'transparent' }}
                      value={stats.attributes[key] ?? ''} 
                      onChange={e => setStats({
                        ...stats, 
                        attributes: { ...stats.attributes, [key]: parseFloat(e.target.value) }
                      })} />
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        <div className="glass-card" style={{ padding: '1rem' }}>
          <div className="glass-header" style={{ color: 'var(--text-main)', opacity: 0.9, marginBottom: '0.8rem' }}>Mob Skills</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {(stats.skills || []).map((sk: any, idx: number) => (
              <div key={idx} style={{ padding: '0.6rem', background: 'rgba(0,0,0,0.2)', borderRadius: 8, borderLeft: `3px solid var(--accent-primary)` }}>
                {isEditing ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    <input className="input-field" placeholder="Skill Name" value={sk.name} style={{ fontWeight: 700, fontSize: '0.8rem', height: '28px' }}
                      onChange={e => {
                        const newSkills = [...stats.skills];
                        newSkills[idx].name = e.target.value;
                        setStats({...stats, skills: newSkills});
                      }} />
                    <textarea className="input-field" placeholder="Description" value={sk.desc} style={{ fontSize: '0.75rem', minHeight: '40px', resize: 'none', padding: '4px 8px' }}
                      onChange={e => {
                        const newSkills = [...stats.skills];
                        newSkills[idx].desc = e.target.value;
                        setStats({...stats, skills: newSkills});
                      }} />
                    <button className="btn-danger" style={{ alignSelf: 'flex-end', padding: '2px 8px', fontSize: '0.65rem' }}
                      onClick={() => {
                        const newSkills = stats.skills.filter((_: any, i: number) => i !== idx);
                        setStats({...stats, skills: newSkills});
                      }}>Remove</button>
                  </div>
                ) : (
                  <>
                    <div style={{ fontWeight: 700, fontSize: '0.8rem', marginBottom: 2, color: 'var(--text-main)' }}>{sk.name}</div>
                    <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', lineHeight: 1.3 }}>{sk.desc}</div>
                  </>
                )}
              </div>
            ))}
            {isEditing && (
              <button className="btn-primary" style={{ marginTop: 4, fontSize: '0.75rem', padding: '6px' }} onClick={() => setStats({...stats, skills: [...(stats.skills || []), {name: 'New Skill', desc: ''}]})}>
                <Plus size={14} /> Add Skill
              </button>
            )}
            {(!stats.skills || stats.skills.length === 0) && !isEditing && (
              <div style={{ textAlign: 'center', color: 'var(--text-muted)', fontSize: '0.75rem', padding: '1rem' }}>No specific skills defined for this mob.</div>
            )}
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
        padding: '1rem', background: 'rgba(0,0,0,0.2)', position: 'relative', cursor: 'pointer', border: 'none', textAlign: 'center', width: '100%',
        transition: 'all 0.2s'
      }}
      onMouseOver={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.05)'; }}
      onMouseOut={e => { e.currentTarget.style.background = 'rgba(0,0,0,0.2)'; }}>
      
      <h3 style={{ fontSize: '0.82rem', fontWeight: 800, color: 'var(--text-main)', textTransform: 'capitalize', margin: 0, opacity: 0.9 }}>{mobType}</h3>
      
      <div style={{ fontSize: '0.6rem', color: group?.color || 'var(--text-muted)', marginTop: 4, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
        {group?.key || 'Mob'}
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
    <div style={{ position: 'relative' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: 10 }}>
        {filtered.map(m => <MobCard key={m} mobType={m} onClick={() => setSelectedMob(m)} />)}
        {filtered.length === 0 && (
          <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)', gridColumn: '1 / -1' }}>
            No enemies found.
          </div>
        )}
      </div>

      {selectedMob && (
        <div style={{ 
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
          background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
          display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000,
          padding: '2rem'
        }} onClick={() => setSelectedMob(null)}>
          <div style={{ 
            width: '100%', maxWidth: '800px', maxHeight: '90vh', overflowY: 'auto',
            background: 'var(--bg-main)', border: '1px solid var(--border-light)',
            borderRadius: 12, padding: '2rem', position: 'relative', boxShadow: '0 20px 40px rgba(0,0,0,0.4)'
          }} onClick={e => e.stopPropagation()}>
            <MobDetailPage 
              mobType={selectedMob} 
              onBack={() => setSelectedMob(null)} 
            />
          </div>
        </div>
      )}
    </div>
  );
}
