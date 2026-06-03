import React, { useState, useEffect } from 'react';
import { Search, Filter } from 'lucide-react';
import api from '../lib/api';

export default function Transactions() {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');

  useEffect(() => {
    const params = {};
    if (filter) params.status = filter;
    api.get('/finance/transactions', { params }).then(res => {
      setTransactions(res.data.data.data || []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [filter]);

  if (loading) return <div className="p-6">Loading...</div>;

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Transaksi</h1>
        <div className="flex gap-3">
          <select
            value={filter}
            onChange={e => setFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-xl outline-none"
          >
            <option value="">Semua Status</option>
            <option value="waiting_payment">Waiting Payment</option>
            <option value="paid">Paid</option>
            <option value="trip_completed">Completed</option>
            <option value="cancelled">Cancelled</option>
            <option value="refund">Refund</option>
          </select>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-100 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-gray-500 border-b border-gray-100 bg-gray-50">
              <th className="p-4 font-medium">Kode</th>
              <th className="p-4 font-medium">Customer</th>
              <th className="p-4 font-medium">Driver</th>
              <th className="p-4 font-medium">Metode</th>
              <th className="p-4 font-medium">Total</th>
              <th className="p-4 font-medium">Komisi</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium">Tanggal</th>
            </tr>
          </thead>
          <tbody>
            {transactions.map(t => (
              <tr key={t.id} className="border-b border-gray-50 hover:bg-gray-50">
                <td className="p-4 font-medium">{t.booking_code}</td>
                <td className="p-4">{t.customer?.fullname}</td>
                <td className="p-4">{t.driver?.user?.fullname || '-'}</td>
                <td className="p-4">{t.payment?.payment_method || '-'}</td>
                <td className="p-4 font-medium">Rp {(t.total_price || 0).toLocaleString()}</td>
                <td className="p-4">Rp {(t.commission_amount || 0).toLocaleString()}</td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium
                    ${t.status === 'trip_completed' ? 'bg-green-100 text-green-700' : ''}
                    ${t.status === 'waiting_payment' ? 'bg-yellow-100 text-yellow-700' : ''}
                    ${t.status === 'cancelled' ? 'bg-red-100 text-red-700' : ''}
                    ${t.status === 'refund' ? 'bg-purple-100 text-purple-700' : ''}
                    ${['paid','driver_confirmed','trip_started'].includes(t.status) ? 'bg-blue-100 text-blue-700' : ''}
                  `}>{t.status}</span>
                </td>
                <td className="p-4">{new Date(t.created_at).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
