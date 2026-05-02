'use client';
import { useState, useEffect } from 'react';
import { Edit3, Check } from 'lucide-react';
import { api } from '../../lib/api';

const ITEM_CATEGORIES = [
  { key: 'consumables', label: 'Consumables', color: '#10b981' },
  { key: 'upgrades',    label: 'Upgrades',    color: '#6366f1' },
  { key: 'equipment',   label: 'Equipment',   color: '#f59e0b' },
  { key: 'special',     label: 'Special',     color: '#ec4899' },
];

function ItemCard({ item }: { item: any }) {
  const [data, setData] = useState({ ...item });
  const [msg, setMsg] = useState('');
  const [isEditing, setIsEditing] = useState(false);

  async function save() {
    try {
      await api.updateItem(item.item_id, data);
      setMsg('Saved');
      setIsEditing(false);
    } catch { setMsg('Error'); }
    setTimeout(() => setMsg(''), 2000);
  }

  return (
    <div className="glass-card" style={{ padding: '0.75rem', background: 'rgba(0,0,0,0.2)', position: 'relative' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <div style={{ fontSize: '0.8rem', fontWeight: 800, color: 'var(--text-main)', opacity: 0.9 }}>{item.display_name}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          {msg && <span style={{ fontSize: '0.65rem', color: msg === 'Error' ? 'var(--danger)' : 'var(--success)', fontWeight: 600 }}>{msg}</span>}
          <button onClick={() => isEditing ? save() : setIsEditing(true)} 
            style={{ background: 'transparent', border: 'none', color: isEditing ? 'var(--accent-primary)' : 'var(--text-muted)', cursor: 'pointer', padding: 2, display: 'flex' }}
            title={isEditing ? 'Save' : 'Edit'}>
            {isEditing ? <Check size={14} /> : <Edit3 size={14} />}
          </button>
        </div>
      </div>
      
      {isEditing ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <div style={{ display: 'flex', gap: 4 }}>
            <label style={{ fontSize: '0.6rem', color: 'var(--text-muted)', flex: 1 }}>PRICE</label>
            <label style={{ fontSize: '0.6rem', color: 'var(--text-muted)', flex: 1 }}>VALUE</label>
          </div>
          <div style={{ display: 'flex', gap: 4 }}>
            <input className="input-field" style={{ fontSize: '0.7rem', height: 26, flex: 1 }} value={data.price} onChange={e => setData({...data, price: +e.target.value})} placeholder="Price" type="number" />
            <input className="input-field" style={{ fontSize: '0.7rem', height: 26, flex: 1 }} value={data.stat_value || ''} onChange={e => setData({...data, stat_value: +e.target.value})} placeholder="Val" type="number" />
          </div>
          <div style={{ display: 'flex', gap: 4 }}>
            <input className="input-field" style={{ fontSize: '0.7rem', height: 26, flex: 1 }} value={data.stat_type || ''} onChange={e => setData({...data, stat_type: e.target.value})} placeholder="Stat Type" />
            <input className="input-field" style={{ fontSize: '0.7rem', height: 26, flex: 1 }} value={data.duration || ''} onChange={e => setData({...data, duration: +e.target.value})} placeholder="Dur (s)" type="number" />
          </div>
          <label style={{ fontSize: '0.6rem', color: 'var(--text-muted)' }}>DESCRIPTION</label>
          <input className="input-field" style={{ fontSize: '0.7rem', height: 26 }} value={data.description} onChange={e => setData({...data, description: e.target.value})} placeholder="Desc" />
          {data.instant_heal !== undefined && (
            <>
              <label style={{ fontSize: '0.6rem', color: 'var(--text-muted)' }}>INSTANT HEAL</label>
              <input className="input-field" style={{ fontSize: '0.7rem', height: 26 }} value={data.instant_heal} onChange={e => setData({...data, instant_heal: +e.target.value})} placeholder="Heal" type="number" />
            </>
          )}
        </div>
      ) : (
        <>
          <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginBottom: 10, height: 32, overflow: 'hidden', lineHeight: 1.4 }}>{item.description}</div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', opacity: 0.8 }}>
            <span style={{ color: 'var(--text-main)', fontWeight: 700 }}>{data.price}G</span>
            {data.stat_type && <span style={{ color: 'var(--text-main)', fontWeight: 600 }}>{data.stat_type.toUpperCase()} +{data.stat_value}</span>}
            {data.instant_heal > 0 && <span style={{ color: 'var(--text-main)', fontWeight: 600 }}>+{data.instant_heal} HP</span>}
          </div>
        </>
      )}
    </div>
  );
}

export default function ItemsTab({ search }: { search: string }) {
  const [items, setItems] = useState<any[]>([]);
  const [activeCat, setActiveCat] = useState<string>(ITEM_CATEGORIES[0].key);

  useEffect(() => {
    api.getItems().then(res => setItems(res.items || []));
  }, []);

  const filteredItems = items.filter(i => {
    const matchesSearch = i.display_name.toLowerCase().includes(search.toLowerCase()) || i.item_id.includes(search.toLowerCase());
    if (search) return matchesSearch;
    return i.category === activeCat;
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div className="no-scrollbar" style={{ display: 'flex', gap: 4, borderBottom: '1px solid var(--border-light)', paddingBottom: 0, overflowX: 'auto' }}>
        {ITEM_CATEGORIES.map(cat => (
          <button key={cat.key} onClick={() => setActiveCat(cat.key)}
            style={{ 
              padding: '8px 20px', background: 'transparent', border: 'none', cursor: 'pointer', 
              fontSize: '0.85rem', fontWeight: 700, textTransform: 'capitalize',
              color: activeCat === cat.key ? 'var(--text-main)' : 'var(--text-muted)',
              borderBottom: activeCat === cat.key ? `2px solid var(--accent-primary)` : '2px solid transparent',
              marginBottom: -1, transition: 'all 0.15s'
            }}>
            {cat.label}
          </button>
        ))}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: 10 }}>
        {filteredItems.map(item => <ItemCard key={item.item_id} item={item} />)}
        {filteredItems.length === 0 && (
          <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>No items found.</div>
        )}
      </div>
    </div>
  );
}
