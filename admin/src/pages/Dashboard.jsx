import React, { useState, useEffect } from 'react';
import { Users, Car, CreditCard, TrendingUp, DollarSign, Calendar } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import api from '../lib/api';

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/dashboard').then(res => {
      setData(res.data.data);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  if (loading) return <div className="p-6"><div className="animate-pulse space-y-4">Loading...</div></div>;

  const stats = data?.stats || {};
  const monthlyRevenue = data?.monthly_revenue || {};

  const chartData = Object.entries(monthlyRevenue).map(([month, revenue]) => ({
    month: ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'][month - 1] || month,
    revenue,
  }));

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard icon={Users} label="Total Customer" value={stats.total_customers} color="blue" />
        <StatCard icon={Car} label="Total Driver" value={stats.total_drivers} color="green" />
        <StatCard icon={CreditCard} label="Total Transaksi" value={stats.total_bookings} color="purple" />
        <StatCard icon={DollarSign} label="Pendapatan" value={`Rp ${(stats.total_revenue || 0).toLocaleString()}`} color="amber" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-8">
        <StatCard icon={TrendingUp} label="Driver Terverifikasi" value={stats.verified_drivers} color="blue" />
        <StatCard icon={Calendar} label="Pending Verifikasi" value={stats.pending_verification} color="orange" />
        <StatCard icon={CreditCard} label="Komisi" value={`Rp ${(stats.total_commission || 0).toLocaleString()}`} color="green" />
      </div>

      {/* Chart */}
      <div className="bg-white rounded-xl p-6 border border-gray-100 mb-8">
        <h2 className="font-semibold mb-4">Pendapatan Bulanan</h2>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="month" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="revenue" fill="#2563EB" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Recent bookings */}
      <div className="bg-white rounded-xl border border-gray-100">
        <div className="p-4 border-b border-gray-100">
          <h2 className="font-semibold">Pesanan Terbaru</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-gray-500 border-b border-gray-100">
                <th className="p-4 font-medium">Kode</th>
                <th className="p-4 font-medium">Customer</th>
                <th className="p-4 font-medium">Driver</th>
                <th className="p-4 font-medium">Total</th>
                <th className="p-4 font-medium">Status</th>
              </tr>
            </thead>
            <tbody>
              {(data?.recent_bookings || []).map(b => (
                <tr key={b.id} className="border-b border-gray-50 hover:bg-gray-50">
                  <td className="p-4 font-medium">{b.booking_code}</td>
                  <td className="p-4">{b.customer?.fullname}</td>
                  <td className="p-4">{b.driver?.user?.fullname || '-'}</td>
                  <td className="p-4">Rp {(b.total_price || 0).toLocaleString()}</td>
                  <td className="p-4">
                    <span className={`px-2 py-1 rounded-full text-xs font-medium
                      ${b.status === 'trip_completed' ? 'bg-green-100 text-green-700' : ''}
                      ${b.status === 'waiting_payment' ? 'bg-yellow-100 text-yellow-700' : ''}
                      ${b.status === 'cancelled' ? 'bg-red-100 text-red-700' : ''}
                      ${['paid','driver_confirmed','driver_on_the_way','trip_started'].includes(b.status) ? 'bg-blue-100 text-blue-700' : ''}
                    `}>{b.status}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function StatCard({ icon: Icon, label, value, color }) {
  const colors = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-green-50 text-green-600',
    purple: 'bg-purple-50 text-purple-600',
    amber: 'bg-amber-50 text-amber-600',
    orange: 'bg-orange-50 text-orange-600',
  };

  return (
    <div className="stat-card flex items-center gap-4">
      <div className={`w-12 h-12 rounded-xl ${colors[color]} flex items-center justify-center`}>
        <Icon size={24} />
      </div>
      <div>
        <p className="text-gray-500 text-sm">{label}</p>
        <p className="text-xl font-bold">{value ?? 0}</p>
      </div>
    </div>
  );
}
