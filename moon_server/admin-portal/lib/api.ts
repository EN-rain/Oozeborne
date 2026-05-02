import axios from 'axios';

export const API_URL = process.env.NEXT_PUBLIC_LOBBY_API_URL || 
  (typeof window !== 'undefined' ? `http://${window.location.hostname}:3000` : 'http://localhost:3000');

export const authHeader = () => ({
  Authorization: `Bearer ${typeof window !== 'undefined' ? localStorage.getItem('moon_token') : ''}`
});

export const api = {
  getStaff: () => axios.get(`${API_URL}/admin/staff`, { headers: authHeader() }).then(res => res.data),
  addStaff: (data: any) => axios.post(`${API_URL}/admin/staff`, data, { headers: authHeader() }).then(res => res.data),
  deleteStaff: (id: string) => axios.delete(`${API_URL}/admin/staff/${id}`, { headers: authHeader() }).then(res => res.data),
  
  getRooms: () => axios.get(`${API_URL}/admin/rooms`, { headers: authHeader() }).then(res => res.data),
  deleteRoom: (code: string) => axios.delete(`${API_URL}/admin/rooms/${code}`, { headers: authHeader() }).then(res => res.data),
  getRoomStats: (roomId: string) => axios.get(`${API_URL}/admin/rooms/${roomId}/stats`, { headers: authHeader() }).then(res => res.data),

  searchPlayers: (q: string) => axios.get(`${API_URL}/admin/players/search?q=${q}`, { headers: authHeader() }).then(res => res.data),
  getPlayer: (userId: string) => axios.get(`${API_URL}/admin/players/${userId}`, { headers: authHeader() }).then(res => res.data),
  playerAction: (data: any) => axios.post(`${API_URL}/admin/player_action`, data, { headers: authHeader() }).then(res => res.data),
  banPlayer: (data: any) => axios.post(`${API_URL}/admin/ban`, data, { headers: authHeader() }).then(res => res.data),

  getItems: () => axios.get(`${API_URL}/admin/items`, { headers: authHeader() }).then(res => res.data),
  updateItem: (id: string, data: any) => axios.patch(`${API_URL}/admin/items/${id}`, data, { headers: authHeader() }).then(res => res.data),

  getMob: (mobType: string) => axios.get(`${API_URL}/admin/mobs/${mobType}`, { headers: authHeader() }).then(res => res.data),
  updateMob: (mobType: string, data: any) => axios.patch(`${API_URL}/admin/mobs/${mobType}`, data, { headers: authHeader() }).then(res => res.data),

  getClass: (classId: string) => axios.get(`${API_URL}/admin/classes/${classId}`, { headers: authHeader() }).then(res => res.data),
  updateClass: (classId: string, data: any) => axios.patch(`${API_URL}/admin/classes/${classId}`, data, { headers: authHeader() }).then(res => res.data),
};
