'use client';
import { useState, useEffect } from 'react';
import { Check, X } from 'lucide-react';
import { api } from '../../lib/api';

const CLASS_TREE: Record<string, string[]> = {
  tank:       ['guardian', 'berserker', 'paladin'],
  dps:        ['assassin', 'ranger', 'mage', 'samurai'],
  support:    ['cleric', 'bard', 'alchemist', 'necromancer'],
  hybrid:     ['spellblade', 'shadow_knight', 'monk'],
  controller: ['chronomancer', 'warden', 'hexbinder', 'stormcaller'],
};

/* ── Stat definitions ─────────────────────────────────────────────────
   initField / perLvlField / maxField:
     plain key  → stats[key]   (fixed DB column)
     'attr:key' → stats.attributes[key]  (attributes JSONB)
   A stat is ONLY shown if its init value is non-zero.
─────────────────────────────────────────────────────────────────────── */
interface StatDef { label: string; initField: string; perLvlField?: string; maxField?: string; step: string; }

const STAT_DEFS: StatDef[] = [
  { label: 'HP',       initField: 'base_max_health',    perLvlField: 'health_per_level',     maxField: 'attr:hp_max',          step: '1'   },
  { label: 'Atk',      initField: 'base_attack_damage', perLvlField: 'damage_per_level',     maxField: 'attr:atk_max',         step: '1'   },
  { label: 'Def',      initField: 'attr:base_defense',  perLvlField: 'attr:def_per_level',   maxField: 'attr:def_max',         step: '1'   },
  { label: 'Mana',     initField: 'base_max_mana',      perLvlField: 'attr:mana_per_level',  maxField: 'attr:mana_max',        step: '1'   },
  { label: 'Speed',    initField: 'base_speed',         perLvlField: 'attr:spd_per_level',   maxField: 'attr:spd_max',         step: '0.5' },
  { label: 'Atk Spd',  initField: 'attr:base_atk_spd', perLvlField: 'attr:atk_spd_per_lvl', maxField: 'attr:atk_spd_max',    step: '0.01'},
  { label: 'Crit Dmg', initField: 'attr:base_crit_dmg', perLvlField: 'attr:crit_dmg_per_lvl',maxField: 'attr:crit_dmg_max',   step: '1'   },
  { label: 'Crit',     initField: 'base_crit_chance',   perLvlField: 'attr:crit_per_level',  maxField: 'attr:crit_max',        step: '0.1' },
];

function getVal(stats: any, field: string): number {
  if (!field) return 0;
  if (field.startsWith('attr:')) return stats.attributes?.[field.slice(5)] ?? 0;
  return stats[field] ?? 0;
}

function setVal(stats: any, field: string, val: number, setStats: (fn: any) => void) {
  if (field.startsWith('attr:')) {
    const k = field.slice(5);
    setStats((p: any) => ({ ...p, attributes: { ...(p.attributes || {}), [k]: val } }));
  } else {
    setStats((p: any) => ({ ...p, [field]: val }));
  }
}

/* ── Skill field extraction ────────────────────────────────────────────
   Groups extra keys by base name, stripping _per_lvl and _max suffixes.
   Shows cooldown, value, then each extra base key — each as a triplet.
─────────────────────────────────────────────────────────────────────── */
interface SkillField { label: string; key: string; init: number; perLvl: number; max: number; }

const LABEL_MAP: Record<string, string> = {
  cooldown: 'CD', value: 'Val', radius: 'Radius', duration: 'Duration',
  damage: 'Dmg', heal: 'Heal', speed: 'Spd', range: 'Range',
  hp_threshold: 'HP%', max_allies: 'Allies', distance: 'Dist',
};
function fmtKey(k: string) {
  return LABEL_MAP[k] || k.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

function getSkillFields(sk: any): SkillField[] {
  const ex = sk.extra || {};
  const fields: SkillField[] = [];

  // ALWAYS show Atk/Val and CD so the layout matches the wireframe even if DB data is missing
  fields.push({
    label: 'Atk/Val', key: 'value',
    init: sk.value ?? 0, perLvl: ex.value_per_lvl ?? 0, max: ex.value_max ?? 0,
  });

  fields.push({
    label: 'CD', key: 'cooldown',
    init: sk.cooldown ?? 0, perLvl: ex.cooldown_per_lvl ?? 0, max: ex.cooldown_max ?? 0,
  });

  const skipExtra = new Set(['value_per_lvl', 'value_max', 'cooldown_per_lvl', 'cooldown_max']);
  Object.keys(ex)
    .filter(k => !k.endsWith('_per_lvl') && !k.endsWith('_max') && !skipExtra.has(k))
    .forEach(k => fields.push({
      label: fmtKey(k), key: `extra.${k}`,
      init: ex[k], perLvl: ex[`${k}_per_lvl`] ?? 0, max: ex[`${k}_max`] ?? 0,
    }));

  return fields;
}

/* ── Tiny number input ─────────────────────────────────────────────── */
function Tiny({ value, onChange, step = 'any' }: { value: number; onChange: (v: number) => void; step?: string }) {
  const [focusVal, setFocusVal] = React.useState<string | null>(null);

  return (
    <input
      type="number" step={step} 
      value={focusVal !== null ? focusVal : value}
      onFocus={() => setFocusVal(String(value))}
      onChange={e => {
        const str = e.target.value;
        setFocusVal(str);
        if (str === '' || str === '-') {
          onChange(0);
        } else {
          const parsed = parseFloat(str);
          if (!isNaN(parsed)) onChange(parsed);
        }
      }}
      onBlur={() => {
        setFocusVal(null);
      }}
      style={{
        width: 40, height: 24, fontSize: '0.68rem', fontWeight: 700,
        textAlign: 'center', padding: '0 3px',
        background: 'rgba(0,0,0,0.4)', border: '1px solid rgba(255,255,255,0.13)',
        borderRadius: 4, color: 'var(--text-main)', outline: 'none',
      }}
    />
  );
}

/* ── Triplet: single stat ──────────────────────────────────────────── */
function Triplet({ label, init, perLvl, max, step, onInit, onPerLvl, onMax }: {
  label: string; init: number; perLvl: number; max: number; step?: string;
  onInit: (v: number) => void; onPerLvl: (v: number) => void; onMax: (v: number) => void;
}) {
  const sub = { fontSize: '0.42rem', color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase' as const, letterSpacing: '0.03em', textAlign: 'center' as const };
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <span style={{ fontSize: '0.6rem', fontWeight: 800, color: 'var(--text-main)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
        {label}
      </span>
      <div style={{ display: 'flex', gap: 3 }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
          <span style={sub}>min</span><Tiny value={init} onChange={onInit} step={step} />
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
          <span style={sub}>per lvl</span><Tiny value={perLvl} onChange={onPerLvl} step={step} />
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
          <span style={sub}>max</span><Tiny value={max} onChange={onMax} step={step} />
        </div>
      </div>
    </div>
  );
const CUSTOM_LABELS: Record<string, string> = {
  "Static Build": "+[[0]]% lightning damage on CC'd targets up to +[[1]]%",
  "Thunder Clap": "Slam ground sending shockwave in 6m radius, stunning for [[0]]s",
  "Shockwave": "Chain of 2 shockwaves (8m range) dealing [[0]] damage + [[1]]% slow for 1s",
  "Fortify": "Gain [[0]]% damage reduction, taunt [[1]]m for [[2]]s",
  "Shield Wall": "-[[0]]% damage, taunt [[1]]m for [[2]]s",
  "Blood Rage": "+[[0]]% atk spd, +[[1]]% dmg for [[2]]s",
  "Divine Shield": "Invulnerable [[0]]s, heal [[1]]% max HP",
  "Burst Window": "+[[0]]% attack, +[[1]]% crit for [[2]]s",
  "Shadow Step": "Teleport, +[[0]]% crit next hit for [[1]]s",
  "Trap Network": "Place [[0]] trap: [[1]] dmg + [[2]]s slow",
  "Meteor Storm": "[[0]] dmg over [[1]]s in large area",
  "Iaijutsu": "[[0]]x dmg after [[1]]s charge",
  "Field Aid": "Restore [[0]] HP over [[1]]s, +[[2]]% defense",
  "Divine Blessing": "Holy zone: [[0]] HP/s, +[[1]]% defense, [[2]]s",
  "Symphony of War": "Allies +[[0]]% dmg, +[[1]]% atk spd for [[2]]s",
  "Plague Flask": "Poison cloud: [[0]] dmg over [[1]]s",
  "Grave Swarm": "[[0]] dmg/s for [[1]]s",
  "Adaptive Stance": "+[[0]]% all stats for [[1]]s",
  "Elemental Infusion": "+[[0]]% elemental dmg for [[1]]s",
  "Dark Pact": "Sacrifice [[0]]% HP, deal [[1]] dmg, heal [[2]]%",
  "Seven-Point Strike": "5 strikes, [[0]] dmg each, final crit + stun [[1]]s",
  "Control Field": "6m zone: [[0]]% slow, [[1]]% enemy dmg, [[2]]s",
  "Time Fracture": "[[0]]% slow enemies, +[[1]]% haste exit, [[2]]s",
  "Bastion Ring": "Ring [[0]]s: [[1]]% slow, root first target",
  "Severing Hex": "Cone: [[0]]% enemy dmg, +[[1]]% ability dmg taken for [[2]]s",
  "Tempest Pulse": "[[0]] dmg, knockback [[1]]m, [[2]]s slow",
};

function MultiTriplet({ group, sk, onUpdate, setStats, stats }: { group: any; sk: any; onUpdate: (idx: number, sub: 'init'|'perLvl'|'max', val: number) => void; setStats: any; stats: any }) {
  const sub = { fontSize: '0.42rem', color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase' as const, letterSpacing: '0.03em', textAlign: 'center' as const, marginBottom: 2 };
  const miniLabel = { fontSize: '0.4rem', color: 'var(--accent-primary)', opacity: 0.8, fontWeight: 700, textTransform: 'uppercase' as const, textAlign: 'center' as const, whiteSpace: 'nowrap' as const, overflow: 'hidden' as const, textOverflow: 'ellipsis' as const, maxWidth: 36 };
  
  const hasMultiple = group.params.length > 1;

  // The raw label string from the DB, or the custom hardcoded map, or the description
  const rawLabel = sk.paramLabel || CUSTOM_LABELS[sk.name] || sk.desc;

  // Create the visually rendered version (replaces [[0]] with the actual value)
  const renderedLabelParts = rawLabel.split(/(\[\[\d+\]\])/).map((segment: string, i: number) => {
    const match = segment.match(/\[\[(\d+)\]\]/);
    if (match) {
      const pIdx = parseInt(match[1], 10);
      const val = group.params[pIdx]?.init ?? 0;
      return <span key={i} style={{ color: '#fff' }}>{val}</span>;
    }
    return <span key={i}>{segment}</span>;
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, marginBottom: 14 }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 2, marginBottom: 4 }}>
        <span style={{ fontSize: '0.65rem', fontWeight: 700, color: 'var(--text-muted)' }}>
          {renderedLabelParts}
        </span>
        <input 
          value={sk.paramLabel ?? ''}
          onChange={(e) => {
            const newSkills = stats.skills.map((s: any) => s.name === sk.name ? { ...s, paramLabel: e.target.value } : s);
            setStats({ ...stats, skills: newSkills });
          }}
          placeholder="Override label manually (use [[0]], [[1]] for params)"
          style={{ background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(255,255,255,0.1)', color: 'var(--text-main)', fontSize: '0.55rem', padding: '2px 4px', borderRadius: 2, width: '100%', outline: 'none' }}
        />
      </div>
      <div style={{ display: 'flex', gap: 16 }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
          <span style={sub}>min</span>
          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap', maxWidth: 140, justifyContent: 'center' }}>
            {group.params.map((p: any, i: number) => (
              <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
                {hasMultiple && <span style={miniLabel}>p{i+1}</span>}
                <Tiny value={p.init} onChange={v => onUpdate(group.startIdx + i, 'init', v)} />
              </div>
            ))}
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
          <span style={sub}>per lvl</span>
          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap', maxWidth: 140, justifyContent: 'center' }}>
            {group.params.map((p: any, i: number) => (
              <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
                {hasMultiple && <span style={miniLabel}>&nbsp;</span>}
                <Tiny value={p.per_lvl} onChange={v => onUpdate(group.startIdx + i, 'perLvl', v)} />
              </div>
            ))}
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
          <span style={sub}>max</span>
          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap', maxWidth: 140, justifyContent: 'center' }}>
            {group.params.map((p: any, i: number) => {
              const init = p.init || 0;
              const perLvl = p.per_lvl || 0;
              const maxVal = p.max || 0;
              const calculatedMax = maxVal !== 0 ? maxVal : Math.round(init + (perLvl * 100));
              return (
                <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
                  {hasMultiple && <span style={miniLabel}>&nbsp;</span>}
                  <Tiny value={calculatedMax} onChange={v => onUpdate(group.startIdx + i, 'max', v)} />
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

function getSkillGroups(sk: any) {
  // Completely remove dynamic text splitting. We only rely on what's explicitly in the DB.
  const hasParams = sk.params && sk.params.length > 0;
  if (!hasParams) return [];
  
  return [{
    label: sk.paramLabel || sk.desc,
    params: sk.params,
    startIdx: 0,
    shortLabels: sk.params.map((_: any, i: number) => `p${i+1}`)
  }];
}

/* ── Class Detail Modal ────────────────────────────────────────────── */
function ClassDetailPage({ classId, onClose }: { classId: string; onClose: () => void }) {
  const [stats, setStats]   = useState<any>({ attributes: {} });
  const [skills, setSkills] = useState<any[]>([]);
  const [msg, setMsg]       = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    api.getClass(classId).then(res => {
      if (res.class) {
        const { skills: s, ...rest } = res.class;
        setStats({ ...rest, attributes: rest.attributes || {} });
        
        // Ensure params exists on all skills for saving
        const safeSkills = (s || []).map((sk: any) => {
          if (!sk.params || sk.params.length === 0) {
             const fallbackGroups = getSkillGroups(sk);
             const builtParams: any[] = [];
             fallbackGroups.forEach(g => builtParams.push(...g.params));
             return { ...sk, params: builtParams };
          }
          return sk;
        });
        setSkills(safeSkills);
      }
    });
  }, [classId]);

  async function save() {
    setSaving(true);
    try { await api.updateClass(classId, { ...stats, skills }); setMsg('Saved ✓'); }
    catch { setMsg('Error'); }
    setSaving(false);
    setTimeout(() => setMsg(''), 2500);
  }

  function updateSkillParam(skillIdx: number, paramIdx: number, sub: 'init'|'perLvl'|'max', val: number) {
    const ns = [...skills];
    const sk = { ...ns[skillIdx], params: [...(ns[skillIdx].params || [])] };
    if (!sk.params[paramIdx]) sk.params[paramIdx] = { init: 0, per_lvl: 0, max: 0 };
    sk.params[paramIdx] = { ...sk.params[paramIdx] };
    
    if (sub === 'init') sk.params[paramIdx].init = val;
    else if (sub === 'perLvl') sk.params[paramIdx].per_lvl = val;
    else sk.params[paramIdx].max = val;
    
    ns[skillIdx] = sk;
    setSkills(ns);
  }

  const isMain     = Object.keys(CLASS_TREE).includes(classId);
  const visibleStats = STAT_DEFS.filter(d => getVal(stats, d.initField) !== 0);

  const panelHdr = { fontSize: '0.55rem', fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase' as const, letterSpacing: '0.1em', marginBottom: 14 };

  const sortedSkills = [...skills].sort((a, b) => {
    const order: Record<string, number> = { 'Special': 1, 'Ability': 2, 'Passive': 3, 'Stat': 4 };
    return (order[a.type] || 99) - (order[b.type] || 99);
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--bg-main)' }}>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 16px', borderBottom: '1px solid var(--border-light)', flexShrink: 0 }}>
        <div>
          <div style={{ fontSize: '0.95rem', fontWeight: 900, textTransform: 'capitalize', color: 'var(--text-main)' }}>
            {classId.replace(/_/g, ' ')}
          </div>
          <div style={{ fontSize: '0.54rem', fontWeight: 700, color: isMain ? 'var(--accent-primary)' : 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
            {isMain ? '● Main Class' : '○ Subclass'}
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {msg && <span style={{ fontSize: '0.68rem', fontWeight: 700, color: msg.includes('Error') ? 'var(--danger)' : 'var(--success)' }}>{msg}</span>}
          <button onClick={save} disabled={saving} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '5px 14px', borderRadius: 5, fontSize: '0.7rem', fontWeight: 800, background: 'var(--accent-primary)', color: '#000', border: 'none', cursor: 'pointer', opacity: saving ? 0.6 : 1 }}>
            <Check size={12} /> Save
          </button>
          <button onClick={onClose} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--text-muted)', display: 'flex' }}>
            <X size={16} />
          </button>
        </div>
      </div>

      {/* Body: 2-column split */}
      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '260px 1fr', minHeight: 0 }}>

        {/* LEFT — Stats */}
        <div style={{ padding: '16px 14px', overflowY: 'auto', borderRight: '1px solid var(--border-light)', background: 'rgba(0,0,0,0.18)' }}>
          <div style={panelHdr}>In Stats</div>
          {visibleStats.length === 0 && (
            <div style={{ fontSize: '0.65rem', color: 'var(--text-muted)', opacity: 0.5 }}>No stats in DB yet.</div>
          )}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 14 }}>
            {visibleStats.map(def => {
              const init = getVal(stats, def.initField) || 0;
              const perLvl = def.perLvlField ? getVal(stats, def.perLvlField) : 0;
              const maxVal = def.maxField ? getVal(stats, def.maxField) : 0;
              const calculatedMax = maxVal !== 0 ? maxVal : Math.round(init + (perLvl * 100));

              return (
                <Triplet
                  key={def.label}
                  label={def.label}
                  step={def.step}
                  init={init}
                  perLvl={perLvl}
                  max={calculatedMax}
                  onInit={v => setVal(stats, def.initField, Math.max(0, v), setStats)}
                  onPerLvl={v => def.perLvlField && setVal(stats, def.perLvlField, Math.max(0, v), setStats)}
                  onMax={v => def.maxField && setVal(stats, def.maxField, Math.max(0, v), setStats)}
                />
              );
            })}
          </div>
        </div>

        {/* RIGHT — Skills */}
        <div style={{ padding: '16px', overflowY: 'auto' }}>
          <div style={panelHdr}>
            Skills
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {sortedSkills.map((sk, skLoopIdx) => {
              const idx = skills.findIndex(s => s.name === sk.name);
              const groups = getSkillGroups(sk);
              return (
                <div key={idx} style={{ padding: '10px 12px', background: 'rgba(0,0,0,0.22)', borderRadius: 8, border: '1px solid rgba(255,255,255,0.06)' }}>
                  {/* Name */}
                  <div style={{ fontSize: '0.78rem', fontWeight: 900, color: 'var(--text-main)', marginBottom: 2 }}>
                    {sk.name} <span style={{ fontSize: '0.55rem', fontWeight: 600, color: 'var(--accent-primary)', marginLeft: 6, textTransform: 'uppercase' }}>{sk.type}</span>
                  </div>
                  {/* Description */}
                  <div style={{ fontSize: '0.63rem', color: 'var(--text-muted)', marginBottom: 12, lineHeight: 1.45 }}>
                    {sk.desc}
                  </div>
                  
                  {/* Dynamic Param Groups */}
                  <div>
                    {groups.map((grp, gIdx) => (
                      <MultiTriplet 
                        key={gIdx} 
                        group={grp} 
                        onUpdate={(paramIdx, sub, val) => updateSkillParam(idx, paramIdx, sub, val)} 
                      />
                    ))}
                  </div>
                </div>
              );
            })}
            {skills.length === 0 && (
              <div style={{ fontSize: '0.85rem', color: 'rgba(255,255,255,0.5)' }}>No skills found.</div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}

/* ── Class grid (main export) ──────────────────────────────────────── */
export default function ClassesTab({ search }: { search: string }) {
  const [selectedClass, setSelectedClass] = useState<string | null>(null);

  const mains    = Object.keys(CLASS_TREE);
  const subs     = Array.from(new Set(Object.values(CLASS_TREE).flat())).filter(s => !mains.includes(s));
  const all      = [...mains, ...subs];
  const filtered = all.filter(c => c.toLowerCase().includes(search.toLowerCase()));

  return (
    <div style={{ position: 'relative' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: 10 }}>
        {filtered.map(clsId => {
          const isMain = mains.includes(clsId);
          return (
            <button key={clsId} onClick={() => setSelectedClass(clsId)} className="glass-card"
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
          <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)', gridColumn: '1 / -1' }}>No classes found.</div>
        )}
      </div>

      {selectedClass && (
        <div
          style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.72)', backdropFilter: 'blur(5px)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000, padding: '1.5rem' }}
          onClick={() => setSelectedClass(null)}
        >
          <div
            style={{ width: '100%', maxWidth: 900, height: 'calc(100vh - 3rem)', background: 'var(--bg-main)', border: '1px solid var(--border-light)', borderRadius: 14, overflow: 'hidden', boxShadow: '0 24px 60px rgba(0,0,0,0.5)', display: 'flex', flexDirection: 'column' }}
            onClick={e => e.stopPropagation()}
          >
            <ClassDetailPage classId={selectedClass} onClose={() => setSelectedClass(null)} />
          </div>
        </div>
      )}
    </div>
  );
}
