'use client';
import { useState } from 'react';
import axios from 'axios';

const API = process.env.NEXT_PUBLIC_LOBBY_API_URL || 
  (typeof window !== 'undefined' ? `http://${window.location.hostname}:3000` : 'http://localhost:3000');

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError]       = useState('');
  const [loading, setLoading]   = useState(false);

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await axios.post(`${API}/auth/login`, { username, password });
      if (res.data.role_level < 2) {
        setError('Access denied: Admin account required.');
        return;
      }
      localStorage.setItem('moon_token', res.data.token);
      localStorage.setItem('moon_user',  JSON.stringify(res.data));
      window.location.href = '/dashboard';
    } catch (err: any) {
      setError(err.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh' }}>
      <div className="glass" style={{ width: 380, padding: '2.5rem' }}>
        {/* Logo */}
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <span style={{ fontSize: '2.5rem' }}>🌙</span>
          <h1 style={{ margin: '0.5rem 0 0', fontSize: '1.4rem', fontWeight: 700, color: '#e2e8f0' }}>
            Moon Control Center
          </h1>
          <p style={{ color: 'var(--moon-muted)', fontSize: '0.85rem', marginTop: 4 }}>
            Staff access only
          </p>
        </div>

        <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <input
            id="username"
            type="text"
            placeholder="Username"
            value={username}
            onChange={e => setUsername(e.target.value)}
            required
            style={inputStyle}
          />
          <input
            id="password"
            type="password"
            placeholder="Password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
            style={inputStyle}
          />
          {error && (
            <p style={{ color: 'var(--moon-danger)', fontSize: '0.85rem', margin: 0 }}>{error}</p>
          )}
          <button id="login-btn" type="submit" className="btn-accent" disabled={loading}
            style={{ marginTop: '0.5rem', padding: '10px' }}>
            {loading ? 'Signing in…' : 'Sign In'}
          </button>
        </form>
      </div>
    </main>
  );
}

const inputStyle: React.CSSProperties = {
  background: 'rgba(255,255,255,0.05)',
  border: '1px solid rgba(255,255,255,0.1)',
  borderRadius: 8,
  padding: '10px 14px',
  color: '#e2e8f0',
  fontSize: '0.95rem',
  outline: 'none',
  width: '100%',
  boxSizing: 'border-box',
};
