import axios from 'axios';
import toast from 'react-hot-toast';

const baseURL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/admin';

const api = axios.create({
  baseURL,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use(config => {
  const token = localStorage.getItem('admin_token');
  if (token) config.headers.Authorization = "Bearer \";
  return config;
});

// Mock interceptor to allow UI testing without backend
api.interceptors.response.use(
  res => res,
  err => {
    // If network error (backend dead/missing), return mock data!
    if (!err.response) {
       console.warn('Backend is offline. Using MOCK DATA for demonstration.');
       const path = err.config.url || '';
       
       if (path.includes('/dashboard')) {
          return Promise.resolve({ data: { data: { 
             stats: { total_customers: 120, total_drivers: 45, active_orders: 12, revenue: 5000000 },
             monthly_revenue: { 1: 1000000, 2: 2500000, 3: 5000000 }
          }}});
       }
       
       if (path.includes('/login')) {
          localStorage.setItem('admin_token', 'mock_token_123');
          return Promise.resolve({ data: { data: { token: 'mock_token_123', user: { name: 'Admin Mock' } } } });
       }

       if (path.includes('/users/customers')) {
          return Promise.resolve({ data: { data: { data: [
              { id: 1, name: 'Budi Santoso', phone: '081234567890', is_active: true, created_at: '2026-01-01' }
          ] } } });
       }
       
       if (path.includes('/users/drivers')) {
          return Promise.resolve({ data: { data: { data: [
              { id: 1, name: 'Sopir Mantap', phone: '081999888777', status: 'active', is_active: true }
          ] } } });
       }

       // Generic fallback for other routes
       return Promise.resolve({ data: { data: { data: [] } } });
    }

    if (err.response?.status === 401) {
      localStorage.removeItem('admin_token');
      window.location.reload();
    }
    
    let msg = err.response?.data?.message || 'Terjadi kesalahan jaringan (Gagal menghubungi API)';
    toast.error(msg);
    return Promise.reject(err);
  }
);

export default api;
