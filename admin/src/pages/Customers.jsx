import React, { useState, useEffect } from 'react';
import { Search, Trash2, ShieldAlert } from 'lucide-react';
import api from '../lib/api';
import toast from 'react-hot-toast';

export default function Customers() {
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    api.get('/users/customers', { params: { search } }).then(res => {
      setCustomers(res.data.data.data || []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [search]);

  const toggleSuspend = async (id, isActive) => {
    if (!confirm(`${isActive ? 'Suspend' : 'Aktifkan'} user ini?`)) return;
    try {
      await api.post(`/users/${id}/suspend`);
      toast.success(`User ${isActive ? 'di-suspend' : 'di-aktifkan'}`);
      setCustomers(customers.map(c => c.id === id ? { ...c, is_active: !isActive } : c));
    } catch {}
  };

  if (loading) return <div className="p-6">Loading...</div>;

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Customer</h1>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Cari customer..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="pl-10 pr-4 py-2 border border-gray-300 rounded-xl outline-none focus:ring-2 focus:ring-primary"
          />
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-100 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-gray-500 border-b border-gray-100 bg-gray-50">
              <th className="p-4 font-medium">ID</th>
              <th className="p-4 font-medium">Nama</th>
              <th className="p-4 font-medium">Telepon</th>
              <th className="p-4 font-medium">Email</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium">Daftar</th>
              <th className="p-4 font-medium">Aksi</th>
            </tr>
          </thead>
          <tbody>
            {customers.map(c => (
              <tr key={c.id} className="border-b border-gray-50 hover:bg-gray-50">
                <td className="p-4 font-medium">#{c.id}</td>
                <td className="p-4">{c.fullname}</td>
                <td className="p-4">{c.phone}</td>
                <td className="p-4">{c.email || '-'}</td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${c.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                    {c.is_active ? 'Aktif' : 'Suspend'}
                  </span>
                </td>
                <td className="p-4">{new Date(c.created_at).toLocaleDateString()}</td>
                <td className="p-4">
                  <button
                    onClick={() => toggleSuspend(c.id, c.is_active)}
                    className="text-red-500 hover:text-red-700"
                    title={c.is_active ? 'Suspend' : 'Aktifkan'}
                  >
                    <ShieldAlert size={18} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
