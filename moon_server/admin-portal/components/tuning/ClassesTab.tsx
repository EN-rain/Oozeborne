'use client';
import { useState, useEffect } from 'react';
import { Edit3, Check } from 'lucide-react';
import { api } from '../../lib/api';

const CLASS_TREE: Record<string, string[]> = {
  tank:       ['guardian', 'berserker', 'paladin'],
  dps:        ['assassin', 'ranger', 'mage', 'samurai'],
  support:    ['cleric', 'bard', 'alchemist', 'necromancer'],
  hybrid:     ['spellblade', 'shadow_knight', 'monk'],
  controller: ['chronomancer', 'warden', 'hexbinder', 'stormcaller'],
};

function ClassDetailPage({ classId, mainClassId, onBack }: { classId: string; mainClassId: string; onBack: () => void }) {
  const statFields = ['base_max_health','base_speed','base_attack_damage','base_crit_chance','base_max_mana','health_per_level','damage_per_level'];
  const [stats, setStats] = useState<any>({});
  const [skills, setSkills] = useState<any[]>([]);
  const [isEditing, setIsEditing] = useState(false);
  const [msg, setMsg] = useState('');

  useEffect(() => {
    api.getClass(classId).then(res => {
      if (res.class) {
        const { skills: s, ...rest } = res.class;
        setStats(rest);
        setSkills(s || []);
      }
    });
  }, [classId]);

  async function save() {
    try {
      await api.updateClass(classId, { ...stats, skills });
      setMsg('Saved');
    } catch { setMsg('Error'); }
    setTimeout(() => setMsg(''), 2000);
  }

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: '1.5rem' }}>
        <button onClick={onBack} className="btn-outline" style={{ padding: '6px 12px' }}>← Back</button>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <h2 style={{ fontSize: '1.1rem', fontWeight: 800, textTransform: 'capitalize', margin: 0, color: 'var(--text-main)' }}>{classId.replace('_',' ')}</h2>
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
        <div className="glass-card">
          <div className="glass-header" style={{ color: 'var(--text-main)', opacity: 0.9 }}>Base Stats</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            {statFields.map(f => (
              <div key={f}>
                <label style={{ fontSize: '0.6rem', color: 'var(--text-muted)', display: 'block', marginBottom: 2, textTransform: 'uppercase', fontWeight: 700 }}>
                  {f === 'damage' || f === 'base_attack_damage' ? 'Attack' : f.replace('base_','').replace(/_/g,' ')}
                </label>
                <input className="input-field" type="number" disabled={!isEditing}
                  style={{ padding: '4px 8px', fontSize: '0.8rem', height: '30px', background: isEditing ? 'var(--bg-input)' : 'transparent', borderColor: isEditing ? 'var(--border-light)' : 'transparent' }}
                  value={stats[f] || 0} onChange={e => setStats({...stats, [f]: +e.target.value})} />
              </div>
            ))}
          </div>
        </div>

        <div className="glass-card">
          <div className="glass-header" style={{ color: 'var(--text-main)', opacity: 0.9 }}>Skills</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {skills.map((sk, idx) => (
              <div key={idx} style={{ padding: '0.6rem', background: 'rgba(0,0,0,0.2)', borderRadius: 8, borderLeft: `3px solid var(--border-light)` }}>
                <div style={{ fontSize: '0.8rem', fontWeight: 700, marginBottom: 3 }}>{sk.name}</div>
                {isEditing
                  ? <input className="input-field" value={sk.desc} style={{ fontSize: '0.75rem', padding: '3px 6px', height: '28px' }} 
                      onChange={e => {
                        const newSkills = [...skills];
                        newSkills[idx].desc = e.target.value;
                        setSkills(newSkills);
                      }} />
                  : <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{sk.desc}</div>
                }
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function ClassesTab({ search }: { search: string }) {
  const [selectedClass, setSelectedClass] = useState<string | null>(null);

  const mains = Object.keys(CLASS_TREE);
  const subs = Array.from(new Set(Object.values(CLASS_TREE).flat())).filter(s => !mains.includes(s));
  const allAvailableClasses = [...mains, ...subs];

  const filtered = allAvailableClasses.filter(c => 
    c.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div style={{ position: 'relative' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: 10 }}>
        {filtered.map(clsId => {
          const isMain = mains.includes(clsId);
          return (
            <button key={clsId} onClick={() => setSelectedClass(clsId)} className="glass-card"
              style={{ 
                padding: '1rem', textAlign: 'center', cursor: 'pointer',
                border: 'none',
                background: 'rgba(0,0,0,0.2)', transition: 'all 0.2s', position: 'relative'
              }}>
              <h4 style={{ margin: 0, fontSize: '0.82rem', fontWeight: 800, textTransform: 'capitalize', color: 'var(--text-main)', opacity: 0.9 }}>{clsId.replace('_', ' ')}</h4>
              <div style={{ fontSize: '0.6rem', color: isMain ? 'var(--accent-primary)' : 'var(--text-muted)', marginTop: 4, fontWeight: 700, textTransform: 'uppercase' }}>
                {isMain ? 'Main Class' : 'Subclass'}
              </div>
            </button>
          );
        })}
        {filtered.length === 0 && (
          <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)', gridColumn: '1 / -1' }}>
            No classes found.
          </div>
        )}
      </div>

      {selectedClass && (
        <div style={{ 
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
          background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
          display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000,
          padding: '2rem'
        }} onClick={() => setSelectedClass(null)}>
          <div style={{ 
            width: '100%', maxWidth: '800px', maxHeight: '90vh', overflowY: 'auto',
            background: 'var(--bg-main)', border: '1px solid var(--border-light)',
            borderRadius: 12, padding: '2rem', position: 'relative', boxShadow: '0 20px 40px rgba(0,0,0,0.4)'
          }} onClick={e => e.stopPropagation()}>
            <ClassDetailPage 
              classId={selectedClass} 
              mainClassId={selectedClass} 
              onBack={() => setSelectedClass(null)} 
            />
          </div>
        </div>
      )}
    </div>
  );
}
