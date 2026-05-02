'use client';
import { useState, useEffect } from 'react';
import { Check, Plus, Trash2, X } from 'lucide-react';
import { api } from '../../lib/api';

const CLASS_TREE: Record<string, string[]> = {
  tank:       ['guardian', 'berserker', 'paladin'],
  dps:        ['assassin', 'ranger', 'mage', 'samurai'],
  support:    ['cleric', 'bard', 'alchemist', 'necromancer'],
  hybrid:     ['spellblade', 'shadow_knight', 'monk'],
  controller: ['chronomancer', 'warden', 'hexbinder', 'stormcaller'],
};

/*
  All fields from Go ClassConfig struct (config.go):
    class_id            — read-only identifier
    display_name        — editable text
    base_max_health     — INT
    base_speed          — FLOAT
    base_attack_damage  — INT
    base_crit_chance    — FLOAT  (%)
    base_max_mana       — INT
    health_per_level    — INT
    damage_per_level    — INT
    skills              — JSONB []Skill{name, desc}
*/

// Stat rows: each has label, sublabel, field key, type, and group color
const STAT_ROWS: {
  label: string;
  sublabel: string;
  field: string;
  type: 'int' | 'float';
  step: string;
  group: string;
}[] = [
  // ── Health ──────────────────────────────────────────────
  { label: 'HP',      sublabel: 'initial',   field: 'base_max_health',    type: 'int',   step: '1',    group: 'Health' },
  { label: 'HP',      sublabel: 'per level', field: 'health_per_level',   type: 'int',   step: '1',    group: 'Health' },
  // ── Mana ─────────────────────────────────────────────────
  { label: 'Mana',    sublabel: 'initial',   field: 'base_max_mana',      type: 'int',   step: '1',    group: 'Mana'   },
  // ── Combat ───────────────────────────────────────────────
  { label: 'Attack',  sublabel: 'initial',   field: 'base_attack_damage', type: 'int',   step: '1',    group: 'Combat' },
  { label: 'Attack',  sublabel: 'per level', field: 'damage_per_level',   type: 'int',   step: '1',    group: 'Combat' },
  { label: 'Crit',    sublabel: 'initial',   field: 'base_crit_chance',   type: 'float', step: '0.1',  group: 'Combat' },
  { label: 'Speed',   sublabel: 'initial',   field: 'base_speed',         type: 'float', step: '0.5',  group: 'Movement' },
];

/* ─── Stat Row Component ───────────────────────────────────────────── */
function StatRow({
  label, sublabel, field, value, step,
  onChange,
}: {
  label: string; sublabel: string; field: string;
  value: number; step: string;
  onChange: (field: string, val: number) => void;
}) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      padding: '5px 10px',
      borderRadius: 6,
      background: 'rgba(0,0,0,0.18)',
      border: '1px solid rgba(255,255,255,0.04)',
    }}>
      {/* accent bar */}
      <div style={{ width: 3, height: 26, borderRadius: 2, background: 'var(--text-muted)', flexShrink: 0 }} />
      {/* label */}
      <div style={{ minWidth: 90 }}>
        <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--text-main)', textTransform: 'uppercase', letterSpacing: '0.04em', lineHeight: 1.1 }}>
          {label}
        </div>
        <div style={{ fontSize: '0.57rem', color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          {sublabel}
        </div>
      </div>
      {/* input */}
      <input
        className="input-field"
        type="number"
        step={step}
        value={value ?? 0}
        onChange={e => onChange(field, parseFloat(e.target.value) || 0)}
        style={{
          flex: 1, padding: '4px 8px', fontSize: '0.82rem', fontWeight: 700,
          height: 28, textAlign: 'right',
          background: 'var(--bg-input)', border: '1px solid var(--border-light)',
          borderRadius: 4, color: 'var(--text-main)',
        }}
      />
    </div>
  );
}

/* ─── Modal Detail ─────────────────────────────────────────────────── */
function ClassDetailPage({ classId, onClose }: { classId: string; onClose: () => void }) {
  const [stats, setStats]   = useState<any>({});
  const [skills, setSkills] = useState<any[]>([]);
  const [msg, setMsg]       = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    api.getClass(classId).then(res => {
      if (res.class) {
        const { skills: s, ...rest } = res.class;
        setStats(rest);
        setSkills(s || []);
      }
    });
  }, [classId]);

  const setStat = (field: string, val: number) =>
    setStats((prev: any) => ({ ...prev, [field]: val }));

  async function save() {
    setSaving(true);
    try {
      await api.updateClass(classId, { ...stats, skills });
      setMsg('Saved ✓');
    } catch { setMsg('Error'); }
    setSaving(false);
    setTimeout(() => setMsg(''), 2500);
  }

  const isMain = Object.keys(CLASS_TREE).includes(classId);

  // Group stat rows
  const groups = Array.from(new Set(STAT_ROWS.map(r => r.group)));

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>

      {/* ── HEADER ── */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '12px 18px',
        borderBottom: '1px solid var(--border-light)',
        flexShrink: 0,
      }}>
        <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          <h2 style={{ margin: 0, fontSize: '0.95rem', fontWeight: 900, textTransform: 'capitalize', color: 'var(--text-main)', letterSpacing: '0.02em' }}>
            {classId.replace(/_/g, ' ')}
          </h2>
          <span style={{ fontSize: '0.58rem', textTransform: 'uppercase', fontWeight: 700, color: isMain ? 'var(--accent-primary)' : 'var(--text-muted)', letterSpacing: '0.06em' }}>
            {isMain ? '● Main Class' : '○ Subclass'}
          </span>
        </div>

        {/* display_name readOnly */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', paddingLeft: 12, borderLeft: '1px solid var(--border-light)' }}>
          <label style={{ fontSize: '0.55rem', color: 'var(--text-muted)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 2 }}>
            Display Name (Read-Only)
          </label>
          <input
            className="input-field"
            type="text"
            readOnly
            value={stats.display_name || ''}
            placeholder={classId.replace(/_/g, ' ')}
            style={{ height: 26, fontSize: '0.8rem', fontWeight: 700, padding: '2px 7px', background: 'var(--bg-input)', border: '1px solid var(--border-light)', borderRadius: 4, color: 'var(--text-main)', opacity: 0.7 }}
          />
        </div>

        {msg && (
          <span style={{ fontSize: '0.72rem', fontWeight: 700, color: msg.includes('Error') ? 'var(--danger)' : 'var(--success)', whiteSpace: 'nowrap' }}>
            {msg}
          </span>
        )}
        <button
          onClick={save}
          disabled={saving}
          style={{
            display: 'flex', alignItems: 'center', gap: 5,
            padding: '6px 14px', borderRadius: 6, fontSize: '0.72rem', fontWeight: 800,
            background: 'var(--accent-primary)', color: '#000', border: 'none', cursor: 'pointer',
            opacity: saving ? 0.6 : 1, flexShrink: 0,
          }}
        >
          <Check size={13} /> Save
        </button>
        <button onClick={onClose} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--text-muted)', padding: 3, display: 'flex', flexShrink: 0 }}>
          <X size={17} />
        </button>
      </div>

      {/* ── BODY ── */}
      <div style={{
        flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr',
        minHeight: 0,
      }}>

        {/* LEFT — Stats */}
        <div style={{
          padding: '12px 14px',
          display: 'flex', flexDirection: 'column', gap: 10,
          borderRight: '1px solid var(--border-light)',
          overflowY: 'auto',
        }}>
          <div style={{ fontSize: '0.58rem', fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
            Base Stats &nbsp;<span style={{ color: 'var(--text-muted)', fontWeight: 400 }}>— all editable</span>
          </div>

          {groups.map(group => (
            <div key={group} style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              {/* group header */}
              <div style={{
                fontSize: '0.54rem', fontWeight: 900, color: 'var(--text-main)',
                textTransform: 'uppercase', letterSpacing: '0.1em',
                borderBottom: `1px solid var(--border-light)`,
                paddingBottom: 3, marginBottom: 1,
              }}>
                {group}
              </div>
              {/* rows for this group */}
              {STAT_ROWS.filter(r => r.group === group).map(row => (
                <StatRow
                  key={row.field}
                  label={row.label}
                  sublabel={row.sublabel}
                  field={row.field}
                  value={stats[row.field] ?? 0}
                  step={row.step}
                  onChange={setStat}
                />
              ))}
            </div>
          ))}
        </div>

        {/* RIGHT — Skills */}
        <div style={{
          padding: '12px 14px',
          display: 'flex', flexDirection: 'column', gap: 10,
          overflowY: 'auto',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
            <div style={{ fontSize: '0.58rem', fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
              Skills&nbsp;<span style={{ color: 'var(--text-main)', fontWeight: 900 }}>{skills.length}</span>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, flex: 1 }}>
            {skills.map((sk, idx) => (
              <div key={idx} style={{
                padding: '9px 11px', background: 'rgba(0,0,0,0.2)',
                borderRadius: 8, borderLeft: '3px solid var(--text-muted)',
                display: 'flex', flexDirection: 'column', gap: 6,
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <input
                    className="input-field"
                    placeholder="Skill name"
                    value={sk.name}
                    readOnly
                    style={{ flex: 1, fontWeight: 800, fontSize: '0.76rem', height: 26, padding: '2px 7px', color: 'var(--text-main)', opacity: 0.7 }}
                  />
                </div>
                <textarea
                  className="input-field"
                  placeholder="Description…"
                  value={sk.desc}
                  readOnly
                  style={{ fontSize: '0.71rem', resize: 'none', minHeight: 42, padding: '4px 7px', lineHeight: 1.4, color: 'var(--text-main)', opacity: 0.7 }}
                />
                <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <span style={{ fontSize: '0.6rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>Cooldown</span>
                    <input
                      className="input-field" type="number" step="0.5" value={sk.cooldown ?? 0}
                      onChange={e => { const ns = [...skills]; ns[idx] = { ...ns[idx], cooldown: parseFloat(e.target.value) || 0 }; setSkills(ns); }}
                      style={{ width: 50, height: 22, fontSize: '0.7rem', padding: '2px 4px', background: 'var(--bg-input)', border: '1px solid var(--border-light)', borderRadius: 4, color: 'var(--text-main)' }}
                    />
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <span style={{ fontSize: '0.6rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>Value</span>
                    <input
                      className="input-field" type="number" step="1" value={sk.value ?? 0}
                      onChange={e => { const ns = [...skills]; ns[idx] = { ...ns[idx], value: parseFloat(e.target.value) || 0 }; setSkills(ns); }}
                      style={{ width: 50, height: 22, fontSize: '0.7rem', padding: '2px 4px', background: 'var(--bg-input)', border: '1px solid var(--border-light)', borderRadius: 4, color: 'var(--text-main)' }}
                    />
                  </div>
                  {/* Dynamic Extra Properties */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap', flex: 1 }}>
                    {sk.extra && Object.entries(sk.extra).map(([k, v]) => (
                      <div key={k} style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                        <span style={{ fontSize: '0.6rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
                          {k.replace(/_/g, ' ')}
                        </span>
                        <input
                          className="input-field" type="number" step="any" value={(v as number) ?? 0}
                          onChange={e => {
                            const ns = [...skills];
                            ns[idx].extra = { ...ns[idx].extra, [k]: parseFloat(e.target.value) || 0 };
                            setSkills(ns);
                          }}
                          style={{ width: 45, height: 22, fontSize: '0.7rem', padding: '2px 4px', background: 'var(--bg-input)', border: '1px solid var(--border-light)', borderRadius: 4, color: 'var(--text-main)' }}
                        />
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ))}
            {skills.length === 0 && (
              <div style={{ textAlign: 'center', color: 'var(--text-muted)', fontSize: '0.7rem', padding: '2rem 0', opacity: 0.55 }}>
                No skills — click Add to create one.
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

/* ─── Main Export ──────────────────────────────────────────────────── */
export default function ClassesTab({ search }: { search: string }) {
  const [selectedClass, setSelectedClass] = useState<string | null>(null);

  const mains = Object.keys(CLASS_TREE);
  const subs  = Array.from(new Set(Object.values(CLASS_TREE).flat())).filter(s => !mains.includes(s));
  const all   = [...mains, ...subs];

  const filtered = all.filter(c => c.toLowerCase().includes(search.toLowerCase()));

  return (
    <div style={{ position: 'relative' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: 10 }}>
        {filtered.map(clsId => {
          const isMain = mains.includes(clsId);
          return (
            <button
              key={clsId}
              onClick={() => setSelectedClass(clsId)}
              className="glass-card"
              style={{ padding: '1rem', textAlign: 'center', cursor: 'pointer', border: 'none', background: 'rgba(0,0,0,0.2)', transition: 'all 0.2s' }}
              onMouseOver={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.06)'; }}
              onMouseOut={e  => { e.currentTarget.style.background = 'rgba(0,0,0,0.2)'; }}
            >
              <h4 style={{ margin: 0, fontSize: '0.82rem', fontWeight: 800, textTransform: 'capitalize', color: 'var(--text-main)', opacity: 0.9 }}>
                {clsId.replace(/_/g, ' ')}
              </h4>
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
        <div
          style={{
            position: 'fixed', inset: 0,
            background: 'rgba(0,0,0,0.72)', backdropFilter: 'blur(5px)',
            display: 'flex', justifyContent: 'center', alignItems: 'center',
            zIndex: 1000, padding: '1.5rem',
          }}
          onClick={() => setSelectedClass(null)}
        >
          <div
            style={{
              width: '100%', maxWidth: 860,
              height: 'calc(100vh - 3rem)',
              background: 'var(--bg-main)',
              border: '1px solid var(--border-light)',
              borderRadius: 14, overflow: 'hidden',
              boxShadow: '0 24px 60px rgba(0,0,0,0.5)',
              display: 'flex', flexDirection: 'column',
            }}
            onClick={e => e.stopPropagation()}
          >
            <ClassDetailPage classId={selectedClass} onClose={() => setSelectedClass(null)} />
          </div>
        </div>
      )}
    </div>
  );
}
