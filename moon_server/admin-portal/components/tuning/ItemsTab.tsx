'use client';
import { useState, useEffect } from 'react';
import { Edit3, Check, X, Package, Tag, Info, Clock, Heart, Zap, Shield, Search } from 'lucide-react';
import { api } from '../../lib/api';

const ITEM_CATEGORIES = [
  { key: 'consumables', label: 'Consumables', color: '#10b981', icon: Heart },
  { key: 'upgrades',    label: 'Upgrades',    color: '#6366f1', icon: Zap },
  { key: 'equipment',   label: 'Equipment',   color: '#f59e0b', icon: Shield },
  { key: 'special',     label: 'Special',     color: '#ec4899', icon: Tag },
];

function ItemEditor({ item, onBack }: { item: any; onBack: () => void }) {
  const [data, setData] = useState({ ...item });
  const [msg, setMsg] = useState('');

  async function save() {
    try {
      await api.updateItem(item.item_id, data);
      setMsg('Stored Successfully');
      setTimeout(() => setMsg(''), 2000);
    } catch { 
      setMsg('Registry Error');
      setTimeout(() => setMsg(''), 3000);
    }
  }

  const StatField = ({ label, sublabel, value, onChange, type = "number", step = "1", disabled = false }: any) => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
        <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--text-muted)', letterSpacing: '0.05em' }}>{label}</span>
        <span style={{ fontSize: '0.55rem', fontWeight: 600, color: 'var(--accent-primary)', opacity: 0.8 }}>{sublabel}</span>
      </div>
      <input 
        className="input-field"
        type={type}
        step={step}
        disabled={disabled}
        value={value ?? ''}
        onChange={e => onChange(type === "number" ? parseFloat(e.target.value) : e.target.value)}
        style={{ 
          fontSize: '0.9rem', 
          height: '34px', 
          background: 'rgba(255,255,255,0.03)',
          border: '1px solid rgba(255,255,255,0.1)',
          padding: '0 10px',
          fontWeight: 600,
          color: disabled ? 'var(--text-muted)' : 'var(--text-main)'
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
              {data.item_id} <span style={{ fontSize: '0.7rem', opacity: 0.5 }}>OBJECT SPEC</span>
            </h2>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
          {msg && <span style={{ fontSize: '0.8rem', fontWeight: 700, color: msg.includes('Error') ? 'var(--danger)' : 'var(--accent-primary)' }}>{msg}</span>}
          <button className="btn-primary" onClick={save} style={{ padding: '8px 24px', fontWeight: 800, fontSize: '0.8rem' }}>
            UPDATE OBJECT
          </button>
        </div>
      </div>

      <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        {/* Left: Attributes */}
        <div className="no-scrollbar" style={{ flex: '0 0 400px', padding: '1.5rem', borderRight: '1px solid var(--border-light)', overflowY: 'auto' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
            
            <section>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12, color: 'var(--accent-primary)' }}>
                <Tag size={14} />
                <span style={{ fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Core Identification</span>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                <StatField label="DISPLAY NAME" sublabel="public" type="text" value={data.display_name} onChange={(v:any) => setData({...data, display_name: v})} />
                <StatField label="ITEM ID" sublabel="immutable" type="text" value={data.item_id} disabled={true} onChange={()=>{}} />
              </div>
            </section>

            <section>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12, color: 'var(--success)' }}>
                <Tag size={14} />
                <span style={{ fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Economic Stats</span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <StatField label="PRICE" sublabel="gold" value={data.price} onChange={(v:any) => setData({...data, price: v})} />
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
                    <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--text-muted)', letterSpacing: '0.05em' }}>CATEGORY</span>
                  </div>
                  <select className="input-field" 
                    style={{ fontSize: '0.9rem', height: '34px', background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.1)', padding: '0 10px', fontWeight: 600, color: 'var(--text-main)' }}
                    value={data.category || 'consumables'} onChange={e => setData({ ...data, category: e.target.value })}>
                    {ITEM_CATEGORIES.map(cat => <option key={cat.key} value={cat.key}>{cat.label}</option>)}
                  </select>
                </div>
              </div>
            </section>

            <section>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12, color: 'var(--warning)' }}>
                <Zap size={14} />
                <span style={{ fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Effect Metrics</span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <StatField label="STAT VALUE" sublabel="modifier" value={data.stat_value} onChange={(v:any) => setData({...data, stat_value: v})} />
                <StatField label="STAT TYPE" sublabel="target" type="text" value={data.stat_type} onChange={(v:any) => setData({...data, stat_type: v})} />
                <StatField label="DURATION" sublabel="seconds" value={data.duration} onChange={(v:any) => setData({...data, duration: v})} />
                <StatField label="INSTANT HEAL" sublabel="hp" value={data.instant_heal} onChange={(v:any) => setData({...data, instant_heal: v})} />
              </div>
            </section>

          </div>
        </div>

        {/* Right: Description & Preview */}
        <div className="no-scrollbar" style={{ flex: 1, padding: '1.5rem', overflowY: 'auto', background: 'rgba(0,0,0,0.1)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16, color: 'var(--text-muted)' }}>
            <Info size={14} />
            <span style={{ fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Lore & Visualization</span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
            <div className="glass-card" style={{ padding: '1.5rem' }}>
              <label style={{ fontSize: '0.6rem', fontWeight: 800, color: 'var(--text-muted)', display: 'block', marginBottom: 8 }}>TOOLTIP DESCRIPTION</label>
              <textarea className="input-field" value={data.description} onChange={e => setData({...data, description: e.target.value})} 
                style={{ fontSize: '0.9rem', minHeight: '120px', lineHeight: 1.6, background: 'transparent' }} />
            </div>

            <div className="glass-card" style={{ padding: '1.5rem', border: '1px dashed rgba(255,255,255,0.1)' }}>
              <div style={{ fontSize: '0.6rem', fontWeight: 800, color: 'var(--text-muted)', marginBottom: 12 }}>LIVE PREVIEW</div>
              <div style={{ display: 'flex', gap: 15, alignItems: 'center' }}>
                <div style={{ width: 60, height: 60, background: 'rgba(255,255,255,0.05)', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Package size={30} style={{ opacity: 0.3 }} />
                </div>
                <div>
                  <div style={{ fontWeight: 800, fontSize: '1.1rem', color: 'var(--text-main)' }}>{data.display_name}</div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--accent-primary)', fontWeight: 700 }}>{data.price} GOLD</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: 4 }}>{data.description}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ItemCard({ item, onClick }: { item: any; onClick: () => void }) {
  const cat = ITEM_CATEGORIES.find(c => c.key === item.category);
  const Icon = cat?.icon || Package;

  return (
    <button onClick={onClick} className="glass-card" 
      style={{ 
        padding: '1rem', background: 'rgba(0,0,0,0.3)', border: '1px solid rgba(255,255,255,0.05)', textAlign: 'left',
        cursor: 'pointer', transition: 'all 0.2s', display: 'flex', flexDirection: 'column', gap: 8
      }}
      onMouseOver={e => { e.currentTarget.style.borderColor = 'var(--accent-primary)'; e.currentTarget.style.background = 'rgba(255,255,255,0.05)'; }}
      onMouseOut={e => { e.currentTarget.style.borderColor = 'rgba(255,255,255,0.05)'; e.currentTarget.style.background = 'rgba(0,0,0,0.3)'; }}>
      
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div style={{ padding: 6, background: 'rgba(0,0,0,0.2)', borderRadius: 4 }}>
          <Icon size={14} style={{ color: cat?.color || 'var(--text-muted)' }} />
        </div>
        <div style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--success)' }}>{item.price}G</div>
      </div>

      <div style={{ fontWeight: 800, fontSize: '0.85rem', color: 'var(--text-main)', textTransform: 'uppercase', letterSpacing: '0.02em' }}>{item.display_name}</div>
      <div style={{ fontSize: '0.65rem', color: 'var(--text-muted)', lineHeight: 1.3, height: 32, overflow: 'hidden' }}>{item.description}</div>
    </button>
  );
}

export default function ItemsTab({ search }: { search: string }) {
  const [items, setItems] = useState<any[]>([]);
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [activeCat, setActiveCat] = useState<string>('all');

  useEffect(() => {
    api.getItems().then(res => setItems(res.items || []));
  }, []);

  const filteredItems = items.filter(i => {
    const matchesSearch = i.display_name.toLowerCase().includes(search.toLowerCase()) || i.item_id.includes(search.toLowerCase());
    const matchesCat = activeCat === 'all' || i.category === activeCat;
    return matchesSearch && matchesCat;
  });

  return (
    <div style={{ height: '100%' }}>
      {selectedItem ? (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 1000 }}>
          <ItemEditor item={selectedItem} onBack={() => setSelectedItem(null)} />
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div style={{ display: 'flex', gap: 10, overflowX: 'auto', paddingBottom: 5 }} className="no-scrollbar">
            <button onClick={() => setActiveCat('all')} 
              style={{ padding: '6px 16px', borderRadius: 20, background: activeCat === 'all' ? 'var(--accent-primary)' : 'rgba(255,255,255,0.05)', border: 'none', color: activeCat === 'all' ? '#000' : 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 800, cursor: 'pointer' }}>
              ALL OBJECTS
            </button>
            {ITEM_CATEGORIES.map(cat => (
              <button key={cat.key} onClick={() => setActiveCat(cat.key)}
                style={{ padding: '6px 16px', borderRadius: 20, background: activeCat === cat.key ? cat.color : 'rgba(255,255,255,0.05)', border: 'none', color: activeCat === cat.key ? '#000' : 'var(--text-muted)', fontSize: '0.75rem', fontWeight: 800, cursor: 'pointer' }}>
                {cat.label.toUpperCase()}
              </button>
            ))}
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: 12 }}>
            {filteredItems.map(item => <ItemCard key={item.item_id} item={item} onClick={() => setSelectedItem(item)} />)}
            {filteredItems.length === 0 && (
              <div style={{ textAlign: 'center', padding: '5rem', color: 'var(--text-muted)', gridColumn: '1 / -1', border: '1px dashed rgba(255,255,255,0.1)', borderRadius: 12 }}>
                <Search size={40} style={{ opacity: 0.2, marginBottom: 15 }} />
                <div style={{ fontWeight: 800, fontSize: '0.9rem', opacity: 0.5 }}>NO OBJECTS FOUND</div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
