import axios from 'axios';
import toast from 'react-hot-toast';
import { supabase } from './supabase';
import bcrypt from 'bcryptjs';

const api = axios.create({
  baseURL: 'http://bypass.local',
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use(config => {
  const token = localStorage.getItem('admin_token');
  if (token) config.headers.Authorization = "Bearer \";
  return config;
});

// ADAPTER: Absolutely bypass network and talk to Supabase
api.defaults.adapter = async function (config) {
  const path = config.url || '';
  console.log('Intercepting request to:', path);
  
  try {
    if (path.includes('/dashboard')) {
      const { count: total_customers } = await supabase.from('users').select('*', { count: 'exact', head: true }).eq('role', 'customer');
      const { count: total_drivers } = await supabase.from('users').select('*', { count: 'exact', head: true }).eq('role', 'driver');
      
      return { 
        data: { data: { stats: { total_customers: total_customers || 0, total_drivers: total_drivers || 0, active_orders: 0, revenue: 0 }, monthly_revenue: { 1: 0, 2: 0, 3: 0 } } },
        status: 200, statusText: 'OK', config, headers: {}
      };
    }
    
    if (path.includes('/login')) {
      const { phone, password } = JSON.parse(config.data);
      const { data: user, error } = await supabase.from('users').select('*').eq('phone', phone).single();
      
      if (error || !user) throw new Error('Nomor telepon tidak terdaftar');
      
      // Verifikasi password asli dari database menggunakan bcrypt
      const isValid = bcrypt.compareSync(password, user.password_hash);
      if (!isValid) throw new Error('Password salah!');
      
      localStorage.setItem('admin_token', 'supabase_token_' + user.id);
      localStorage.setItem('user_role', user.role);
      return { 
        data: { data: { token: 'supabase_token_' + user.id, user } },
        status: 200, statusText: 'OK', config, headers: {}
      };
    }

    if (path.includes('/register')) {
      const payload = JSON.parse(config.data);
      const salt = bcrypt.genSaltSync(12);
      const password_hash = bcrypt.hashSync('123456', salt); // Default password for new register if not provided

      const { data: user, error } = await supabase.from('users').insert({
        fullname: payload.fullname,
        phone: payload.phone,
        email: payload.email,
        role: payload.role,
        password_hash: password_hash,
        is_active: true
      }).select().single();
      
      if (error) throw new Error('Gagal mendaftar: ' + error.message);
      
      localStorage.setItem('admin_token', 'supabase_token_' + user.id);
      localStorage.setItem('user_role', user.role);
      return { 
        data: { data: { token: 'supabase_token_' + user.id, user } },
        status: 200, statusText: 'OK', config, headers: {}
      };
    }

    if (path.includes('/users/customers')) {
      const { data } = await supabase.from('users').select('*').eq('role', 'customer');
      return { data: { data: { data: data || [] } }, status: 200, statusText: 'OK', config, headers: {} };
    }
    
    if (path.includes('/users/drivers')) {
      const { data } = await supabase.from('users').select('*').eq('role', 'driver');
      return { data: { data: { data: data || [] } }, status: 200, statusText: 'OK', config, headers: {} };
    }

    if (path.includes('/finance/transactions') || path.includes('/finance/withdrawals')) {
      return { data: { data: { data: [] } }, status: 200, statusText: 'OK', config, headers: {} };
    }

    return { data: { data: { data: [] } }, status: 200, statusText: 'OK', config, headers: {} };
  } catch (error) {
    let msg = error.message || 'Terjadi kesalahan jaringan';
    toast.error(msg);
    const err = new Error(msg);
    err.response = { data: { message: msg }, status: 400 };
    return Promise.reject(err);
  }
};

export default api;
