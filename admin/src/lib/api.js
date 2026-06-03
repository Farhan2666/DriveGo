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

api.interceptors.response.use(
  res => res,
  err => {
    if (err.response?.status === 401) {
      localStorage.removeItem('admin_token');
      window.location.reload();
    }
    
    let msg = err.response?.data?.message || 'Terjadi kesalahan jaringan (Backend mungkin sedang tidur, tunggu 30 detik lalu refresh)';
    toast.error(msg);
    return Promise.reject(err);
  }
);

export default api;
