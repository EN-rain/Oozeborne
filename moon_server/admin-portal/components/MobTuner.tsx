'use client';
import { useState } from 'react';
import { Search } from 'lucide-react';
import EnemiesTab from './tuning/EnemiesTab';
import ItemsTab from './tuning/ItemsTab';
import ClassesTab from './tuning/ClassesTab';

export default function MobTuner() {
  const [tab, setTab] = useState<'enemies'|'items'|'classes'>('enemies');
  const [search, setSearch] = useState('');
  const tabs: { key: 'enemies'|'items'|'classes'; label: string }[] = [
    { key: 'enemies', label: 'Enemies' },
    { key: 'items',   label: 'Items' },
    { key: 'classes', label: 'Classes' },
  ];

  return (
    <section>
      <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '2rem' }}>
        <div style={{ position: 'relative', width: '380px' }}>
          <Search size={18} style={{ position: 'absolute', left: 16, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
          <input className="input-field"
            style={{ 
              background: 'rgba(0,0,0,0.2)', 
              border: '1px solid var(--border-light)', 
              borderRadius: 30, 
              paddingLeft: 46, 
              fontSize: '0.85rem', 
              height: 44 
            }}
            placeholder={`Search ${tab}...`} value={search} onChange={e => setSearch(e.target.value)} />
        </div>
      </div>

      <div className="no-scrollbar" style={{ display: 'flex', gap: 8, marginBottom: '1.5rem', borderBottom: '1px solid var(--border-light)', paddingBottom: 0, overflowX: 'auto' }}>
        {tabs.map(t => (
          <button key={t.key} onClick={() => { setTab(t.key); setSearch(''); }}
            style={{ 
              padding: '8px 20px', background: 'transparent', border: 'none', cursor: 'pointer', 
              fontSize: '0.85rem', fontWeight: 700,
              color: tab === t.key ? 'var(--text-main)' : 'var(--text-muted)',
              borderBottom: tab === t.key ? '2px solid var(--accent-primary)' : '2px solid transparent',
              marginBottom: -1, transition: 'all 0.15s' 
            }}>
            {t.label}
          </button>
        ))}
      </div>
      {tab === 'enemies' && <EnemiesTab search={search} />}
      {tab === 'items'   && <ItemsTab search={search} />}
      {tab === 'classes' && <ClassesTab search={search} />}
    </section>
  );
}
