import React, { useState, useEffect } from 'react';
import { CheckCircle, XCircle } from 'lucide-react';
import api from '../lib/api';
import toast from 'react-hot-toast';

export default function Withdrawals() {
  const [withdrawals, setWithdrawals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');

  useEffect(() => {
    const params = {};
    if (filter) params.status = filter;
    api.get('/finance/withdrawals', { params }).then(res => {
      setWithdrawals(res.data.data.data || []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [filter]);

  const handleAction = async (id, action) => {
    if (!confirm(`${action === 'approve' ? 'Setujui' : 'Tolak'} withdrawal ini?`)) return;
    try {
      await api.post(`/finance/withdrawals/${id}/${action}`);
      toast.success('Berhasil');
      setWithdrawals(withdrawals.map(w =>
        w.id === id ? { ...w, status: action === 'approve' ? 'completed' : 'rejected' } : w
      ));
    } catch {}
  };

  if (loading) return <div className="p-6">Loading...</div>;

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Withdrawal</h1>
        <select
          value={filter}
          onChange={e => setFilter(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-xl outline-none"
        >
          <option value="">Semua Status</option>
          <option value="pending">Pending</option>
          <option value="completed">Completed</option>
          <option value="rejected">Rejected</option>
        </select>
      </div>

      <div className="bg-white rounded-xl border border-gray-100 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-gray-500 border-b border-gray-100 bg-gray-50">
              <th className="p-4 font-medium">ID</th>
              <th className="p-4 font-medium">Driver</th>
              <th className="p-4 font-medium">Bank</th>
              <th className="p-4 font-medium">No. Rekening</th>
              <th className="p-4 font-medium">Jumlah</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium">Tanggal</th>
              <th className="p-4 font-medium">Aksi</th>
            </tr>
          </thead>
          <tbody>
            {withdrawals.map(w => (
              <tr key={w.id} className="border-b border-gray-50 hover:bg-gray-50">
                <td className="p-4 font-medium">#{w.id}</td>
                <td className="p-4">{w.driver?.user?.fullname}</td>
                <td className="p-4">{w.bank_name}</td>
                <td className="p-4 font-mono">{w.bank_account_number}</td>
                <td className="p-4 font-medium text-green-600">Rp {(w.amount || 0).toLocaleString()}</td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium
                    ${w.status === 'completed' ? 'bg-green-100 text-green-700' : ''}
                    ${w.status === 'pending' ? 'bg-yellow-100 text-yellow-700' : ''}
                    ${w.status === 'rejected' ? 'bg-red-100 text-red-700' : ''}
                  `}>{w.status}</span>
                </td>
                <td className="p-4">{new Date(w.created_at).toLocaleDateString()}</td>
                <td className="p-4">
                  {w.status === 'pending' && (
                    <div className="flex gap-1">
                      <button onClick={() => handleAction(w.id, 'approve')} className="p-1.5 text-green-500 hover:bg-green-50 rounded-lg">
                        <CheckCircle size={16} />
                      </button>
                      <button onClick={() => handleAction(w.id, 'reject')} className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg">
                        <XCircle size={16} />
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
