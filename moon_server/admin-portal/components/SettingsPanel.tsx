'use client';
import { useEffect, useState } from 'react';
import { Settings, Trash2, Plus } from 'lucide-react';
import { api } from '../lib/api';

export default function SettingsPanel() {
  const [staff, setStaff] = useState<any[]>([]);
  const [newAdmin, setNewAdmin] = useState({ user: '', pass: '', level: 1 });
  const [loading, setLoading] = useState(false);

  const fetchStaff = async () => {
    try {
      const res = await api.getStaff();
      setStaff(res.staff || []);
    } catch {}
  };

  useEffect(() => { fetchStaff(); }, []);

  async function addStaff() {
    if (!newAdmin.user || !newAdmin.pass) return;
    setLoading(true);
    try {
      await api.addStaff({ username: newAdmin.user, password: newAdmin.pass, role_level: +newAdmin.level });
      setNewAdmin({ user: '', pass: '', level: 1 });
      fetchStaff();
    } catch (e: any) { alert(e.response?.data?.error || 'Failed to add admin'); }
    finally { setLoading(false); }
  }

  async function deleteStaff(id: string) {
    if (!confirm('Permanently remove this staff member?')) return;
    try {
      await api.deleteStaff(id);
      fetchStaff();
    } catch {}
  }

  return (
    <section className="glass-card">
      <div className="glass-header">
        <Settings size={18} className="text-accent-primary" /> Staff Management
      </div>
      
      <div style={{ marginBottom: '2rem' }}>
        <h4 style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: 12, fontWeight: 500 }}>ADD NEW ADMINISTRATOR</h4>
        <div style={{ display: 'flex', gap: 12 }}>
          <input className="input-field" placeholder="Username" 
            value={newAdmin.user} onChange={e => setNewAdmin({...newAdmin, user: e.target.value})} />
          <input className="input-field" placeholder="Password" type="password"
            value={newAdmin.pass} onChange={e => setNewAdmin({...newAdmin, pass: e.target.value})} />
          <button className="btn-primary" onClick={addStaff} disabled={loading}><Plus size={16} /> Add</button>
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th>User</th>
            <th>Role Level</th>
            <th style={{ width: 80, textAlign: 'center' }}>Actions</th>
          </tr>
        </thead>
        <tbody>
          {staff.map(s => (
            <tr key={s.user_id}>
              <td style={{ fontWeight: 500 }}>{s.username}</td>
              <td>
                {s.role_level === 2 
                  ? <span className="badge badge-success">SuperAdmin</span> 
                  : <span className="badge badge-info">Admin</span>}
              </td>
              <td style={{ textAlign: 'center' }}>
                <button className="btn-danger" style={{ padding: '4px 8px', borderRadius: 6, cursor: 'pointer' }} 
                  onClick={() => deleteStaff(s.user_id)}>
                  <Trash2 size={14} />
                </button>
              </td>
            </tr>
          ))}
          {staff.length === 0 && (
            <tr><td colSpan={3} style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No staff members found.</td></tr>
          )}
        </tbody>
      </table>
    </section>
  );
}
