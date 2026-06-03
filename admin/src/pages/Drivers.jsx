import React, { useState, useEffect } from 'react';
import { Search, CheckCircle, XCircle, Ban, Eye } from 'lucide-react';
import { Link } from 'react-router-dom';
import api from '../lib/api';
import toast from 'react-hot-toast';

export default function Drivers() {
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('');

  useEffect(() => {
    const params = { search };
    if (filter) params.verification_status = filter;
    api.get('/users/drivers', { params }).then(res => {
      setDrivers(res.data.data.data || []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [search, filter]);

  const handleAction = async (id, action) => {
    const confirmMsg = {
      approve: 'Setujui driver ini?',
      reject: 'Tolak driver ini?',
      ban: 'Ban driver ini?',
      unban: 'Aktifkan driver ini?',
    };
    if (!confirm(confirmMsg[action])) return;

    try {
      await api.post(`/users/drivers/${id}/${action}`);
      toast.success('Berhasil');
      setDrivers(drivers.map(d =>
        d.id === id ? {
          ...d,
          is_verified: action === 'approve' ? true : d.is_verified,
          verification_status: action === 'approve' ? 'verified' : action === 'reject' ? 'rejected' : d.verification_status,
          user: { ...d.user, is_active: action === 'unban' ? true : action === 'ban' ? false : d.user?.is_active },
        } : d
      ));
    } catch {}
  };

  if (loading) return <div className="p-6">Loading...</div>;

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Driver</h1>
        <div className="flex gap-3">
          <select
            value={filter}
            onChange={e => setFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-xl outline-none"
          >
            <option value="">Semua Status</option>
            <option value="pending">Pending</option>
            <option value="verified">Terverifikasi</option>
            <option value="rejected">Ditolak</option>
          </select>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
            <input
              type="text"
              placeholder="Cari driver..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="pl-10 pr-4 py-2 border border-gray-300 rounded-xl outline-none focus:ring-2 focus:ring-primary"
            />
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-100 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-gray-500 border-b border-gray-100 bg-gray-50">
              <th className="p-4 font-medium">ID</th>
              <th className="p-4 font-medium">Nama</th>
              <th className="p-4 font-medium">Telepon</th>
              <th className="p-4 font-medium">Rating</th>
              <th className="p-4 font-medium">Verifikasi</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium">Aksi</th>
            </tr>
          </thead>
          <tbody>
            {drivers.map(d => (
              <tr key={d.id} className="border-b border-gray-50 hover:bg-gray-50">
                <td className="p-4 font-medium">#{d.id}</td>
                <td className="p-4">
                  <Link to={`/drivers/${d.id}`} className="text-primary hover:underline font-medium">
                    {d.user?.fullname}
                  </Link>
                </td>
                <td className="p-4">{d.user?.phone}</td>
                <td className="p-4">
                  <span className="text-amber-500">★</span> {d.rating?.toFixed(1) || '0'}
                </td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium
                    ${d.verification_status === 'verified' ? 'bg-green-100 text-green-700' : ''}
                    ${d.verification_status === 'pending' ? 'bg-yellow-100 text-yellow-700' : ''}
                    ${d.verification_status === 'rejected' ? 'bg-red-100 text-red-700' : ''}
                  `}>
                    {d.verification_status}
                  </span>
                </td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${d.user?.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                    {d.user?.is_active ? 'Aktif' : 'Banned'}
                  </span>
                </td>
                <td className="p-4">
                  <div className="flex gap-1">
                    <Link to={`/drivers/${d.id}`} className="p-1.5 text-gray-400 hover:text-primary rounded-lg hover:bg-gray-100">
                      <Eye size={16} />
                    </Link>
                    {d.verification_status === 'pending' && (
                      <>
                        <button onClick={() => handleAction(d.id, 'approve')} className="p-1.5 text-green-500 hover:bg-green-50 rounded-lg">
                          <CheckCircle size={16} />
                        </button>
                        <button onClick={() => handleAction(d.id, 'reject')} className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg">
                          <XCircle size={16} />
                        </button>
                      </>
                    )}
                    {d.user?.is_active
                      ? <button onClick={() => handleAction(d.id, 'ban')} className="p-1.5 text-orange-500 hover:bg-orange-50 rounded-lg">
                          <Ban size={16} />
                        </button>
                      : <button onClick={() => handleAction(d.id, 'unban')} className="p-1.5 text-green-500 hover:bg-green-50 rounded-lg">
                          <CheckCircle size={16} />
                        </button>
                    }
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
