import React, { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import api from '../lib/api';

const COLORS = ['#2563EB', '#F59E0B', '#10B981', '#EF4444', '#8B5CF6'];

export default function Reports() {
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(true);
  const [type, setType] = useState('monthly');

  useEffect(() => {
    api.get('/finance/reports', { params: { type } }).then(res => {
      setReport(res.data.data);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [type]);

  if (loading) return <div className="p-6">Loading...</div>;

  const data = report?.report || [];
  const paymentSummary = report?.payment_summary || [];

  const barData = data.map(r => ({
    name: r.period,
    revenue: r.total_revenue || 0,
    commission: r.total_commission || 0,
  }));

  const pieData = paymentSummary.map(p => ({
    name: p.payment_method || 'Unknown',
    value: p.total_amount || 0,
  }));

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Laporan</h1>
        <select
          value={type}
          onChange={e => setType(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-xl outline-none"
        >
          <option value="daily">Harian</option>
          <option value="monthly">Bulanan</option>
          <option value="yearly">Tahunan</option>
        </select>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div className="stat-card">
          <p className="text-gray-500 text-sm">Total Pesanan</p>
          <p className="text-2xl font-bold">
            {data.reduce((sum, r) => sum + (r.total_bookings || 0), 0)}
          </p>
        </div>
        <div className="stat-card">
          <p className="text-gray-500 text-sm">Total Pendapatan</p>
          <p className="text-2xl font-bold text-green-600">
            Rp {data.reduce((sum, r) => sum + (r.total_revenue || 0), 0).toLocaleString()}
          </p>
        </div>
        <div className="stat-card">
          <p className="text-gray-500 text-sm">Total Komisi</p>
          <p className="text-2xl font-bold text-primary">
            Rp {data.reduce((sum, r) => sum + (r.total_commission || 0), 0).toLocaleString()}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue chart */}
        <div className="bg-white rounded-xl p-6 border border-gray-100">
          <h3 className="font-semibold mb-4">Pendapatan & Komisi</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={barData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="revenue" name="Pendapatan" fill="#2563EB" radius={[4, 4, 0, 0]} />
              <Bar dataKey="commission" name="Komisi" fill="#F59E0B" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Payment method pie */}
        <div className="bg-white rounded-xl p-6 border border-gray-100">
          <h3 className="font-semibold mb-4">Metode Pembayaran</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={pieData}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={100}
                dataKey="value"
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
              >
                {pieData.map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-gray-100 mt-6 overflow-hidden">
        <div className="p-4 border-b border-gray-100">
          <h3 className="font-semibold">Detail Laporan</h3>
        </div>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-gray-500 border-b border-gray-100 bg-gray-50">
              <th className="p-4 font-medium">Periode</th>
              <th className="p-4 font-medium">Pesanan</th>
              <th className="p-4 font-medium">Pendapatan</th>
              <th className="p-4 font-medium">Komisi</th>
              <th className="p-4 font-medium">Rata-rata</th>
            </tr>
          </thead>
          <tbody>
            {data.map((r, i) => (
              <tr key={i} className="border-b border-gray-50 hover:bg-gray-50">
                <td className="p-4 font-medium">{r.period}</td>
                <td className="p-4">{r.total_bookings}</td>
                <td className="p-4">Rp {(r.total_revenue || 0).toLocaleString()}</td>
                <td className="p-4">Rp {(r.total_commission || 0).toLocaleString()}</td>
                <td className="p-4">Rp {(r.avg_order_value || 0).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
