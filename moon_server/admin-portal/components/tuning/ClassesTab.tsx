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
  const [focusVal, setFocusVal] = useState<string | null>(null);

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
}

const PARAM_LABELS: Record<string, string[]> = {
  "Static Build": ["dmg boost", "max boost"],
  "Thunder Clap": ["stun dur"],
  "Shockwave": ["damage", "slow %"],
  "Fortify": ["dmg red", "taunt rad", "duration"],
  "Shield Wall": ["dmg red", "taunt rad", "duration"],
  "Blood Rage": ["atk spd", "dmg boost", "duration"],
  "Divine Shield": ["invuln", "heal %"],
  "Burst Window": ["atk boost", "crit boost", "duration"],
  "Shadow Step": ["crit boost", "duration"],
  "Trap Network": ["traps", "damage", "slow dur"],
  "Meteor Storm": ["damage", "duration"],
  "Iaijutsu": ["dmg mult", "charge dur"],
  "Field Aid": ["heal", "duration", "def boost"],
  "Divine Blessing": ["heal/s", "duration", "def boost"],
  "Symphony of War": ["dmg boost", "atk spd", "duration"],
  "Plague Flask": ["damage", "duration"],
  "Grave Swarm": ["dmg/s", "duration"],
  "Adaptive Stance": ["stat boost", "duration"],
  "Elemental Infusion": ["elem dmg", "duration"],
  "Dark Pact": ["hp cost", "damage", "heal %"],
  "Seven-Point Strike": ["damage", "stun dur"],
  "Control Field": ["slow %", "enemy dmg", "duration"],
  "Time Fracture": ["slow %", "haste %", "duration"],
  "Bastion Ring": ["duration", "slow %"],
  "Severing Hex": ["enemy dmg", "vuln %", "duration"],
  "Tempest Pulse": ["damage", "knockback", "slow dur"],
  "Taunt": ["duration"],
  "Unbreakable": ["dmg red"],
  "Aegis Slam": ["damage"],
  "Bulwark Cry": ["duration"],
  "Frenzy": ["duration"],
  "Leap Smash": ["damage"],
  "War Cry": ["def drop", "duration"],
  "Adrenaline": ["dmg boost", "max boost"],
  "Holy Strike": ["damage", "slow dur"],
  "Consecrate": ["dmg/s", "duration"],
  "Surge": ["duration"],
  "Executioner": ["dmg boost"],
  "Shadow Teleport": ["crit chance"],
  "Smoke Bomb": ["duration"],
  "Blade Storm": ["damage"],
  "Backstab": ["dmg boost"],
  "Trap Master": ["traps", "damage"],
  "Volley": ["arrows", "damage"],
  "Hawk Strike": ["damage", "stun dur"],
  "Hunter's Mark": ["duration", "dmg vuln"],
  "Meteor Shower": ["damage", "duration"],
  "Frost Nova": ["damage", "freeze dur"],
  "Chain Lightning": ["targets", "damage"],
  "Mana Shield": ["conversion"],
  "Quick-Draw Strike": ["dmg mult"],
  "Whirlwind Slash": ["damage"],
  "Death Mark": ["dmg mult", "def ignore"],
  "Way of the Warrior": ["dmg boost", "max boost"],
  "Revitalize": ["heal", "def boost", "duration"],
  "Steady Hands": ["cd red", "regen boost"],
  "Holy Ground": ["heal/s", "def boost", "duration"],
  "Resurrection Pulse": ["heal"],
  "Shield of Faith": ["hits", "duration"],
  "Healing Aura": ["heal/s", "heal amp"],
  "Battle Hymn": ["duration", "dmg boost", "atk spd"],
  "Dissonance": ["stun dur"],
  "Rallying Tune": ["debuffs", "resist", "duration"],
  "Inspiring Presence": ["dmg boost", "dmg reduction"],
  "Healing Flask": ["heal"],
  "Acid Splash": ["damage", "armor drop", "duration"],
  "Healing Brew": ["heal"],
  "Transmutation": ["potion amp", "poison chance"],
  "Summon Undead": ["skeletons", "hp", "damage"],
  "Bone Spike": ["damage"],
  "Death Shroud": ["duration", "dmg return"],
  "Soul Harvest": ["heal"],
  "Elemental Strike": ["damage"],
  "Versatility": ["cost red", "mana return"],
  "Blade Burst": ["damage"],
  "Arcane Dash": ["dmg/s", "duration"],
  "Spell Parry": ["damage", "duration"],
  "Arcane Strike": ["dmg boost"],
  "Void Strike": ["damage", "heal %"],
  "Shadow Burst": ["damage", "slow %", "duration"],
  "Soul Rend": ["damage", "heal"],
  "Vampiric Embrace": ["lifesteal amp", "heal amp"],
  "Flurry": ["hits", "stun dur"],
  "Pressure Point": ["stun dur", "damage"],
  "Wind Step": ["damage"],
  "Flow State": ["atk spd", "dodge boost"],
  "Displace": ["distance"],
  "Tempo Lock": ["dmg red"],
  "Slow Field": ["slow %", "duration"],
  "Time Freeze": ["freeze dur"],
  "Rewind": ["rewind dur"],
  "Borrowed Seconds": ["cd red"],

  "Vine Snare": ["root dur"],
  "Bramble Wall": ["duration", "damage"],
  "Line Holder": ["enemy dmg"],
  "Hex Cone": ["enemy dmg", "vuln %"],
  "Cursed Ground": ["duration", "stat drop"],
  "Hex Bolt": ["duration"],
  "Malice Chain": ["spread chance"],
  "Static Field": ["duration", "dmg return"],
  // Missing skills found in DB
  "Allied Ward": ["per ally %", "max %"],
  "Divine Aegis": ["invuln", "heal %"],
  "Holy Light": ["lifesteal %", "kill heal"],
  "Mystic Armor": ["armor", "spell res"],
  "Ring of Thorns": ["duration", "dmg/s"],
};

function MultiTriplet({ group, sk, onUpdate, setStats, stats }: { group: any; sk: any; onUpdate: (idx: number, sub: 'init'|'perLvl'|'max', val: number) => void; setStats: any; stats: any }) {
  const sub = { fontSize: '0.42rem', color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase' as const, letterSpacing: '0.03em', textAlign: 'center' as const, marginBottom: 2 };
  const paramNameStyle = { fontSize: '0.5rem', color: 'var(--accent-primary)', fontWeight: 800, textTransform: 'uppercase' as const, letterSpacing: '0.05em', textAlign: 'center' as const, marginBottom: 4, whiteSpace: 'nowrap' as const };
  
  const labels = PARAM_LABELS[sk.name] || [];

  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 14, marginBottom: 14 }}>
      {group.params.map((p: any, i: number) => {
        const init = p.init ?? 0;
        const perLvl = p.per_lvl ?? 0;
        const maxVal = p.max ?? 0;
        const calculatedMax = maxVal !== 0 ? maxVal : Math.round(init + (perLvl * 100));
        const label = labels[i] || `p${i + 1}`;
        return (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
            <span style={paramNameStyle}>{label}</span>
            <div style={{ display: 'flex', gap: 4 }}>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
                <span style={sub}>min</span>
                <Tiny value={init} onChange={v => onUpdate(group.startIdx + i, 'init', v)} />
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
                <span style={sub}>per lvl</span>
                <Tiny value={perLvl} onChange={v => onUpdate(group.startIdx + i, 'perLvl', v)} />
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
                <span style={sub}>max</span>
                <Tiny value={calculatedMax} onChange={v => onUpdate(group.startIdx + i, 'max', v)} />
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

function getSkillGroups(sk: any) {
  const hasParams = sk.params && sk.params.length > 0;
  if (!hasParams) {
    // Fallback: If no params in DB, provide 1 default triplet group so they can edit values
    return [{
      label: sk.paramLabel || sk.desc,
      params: [{ init: 0, per_lvl: 0, max: 0 }],
      startIdx: 0,
      shortLabels: ['p1']
    }];
  }
  
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
                        sk={sk}
                        stats={stats}
                        setStats={setStats}
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
