import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { Car, Phone, Mail, Star, CheckCircle, XCircle, Award } from 'lucide-react';
import api from '../lib/api';
import toast from 'react-hot-toast';

export default function DriverDetail() {
  const { id } = useParams();
  const [driver, setDriver] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get(`/users/drivers/${id}`).then(res => {
      setDriver(res.data.data);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="p-6">Loading...</div>;
  if (!driver) return <div className="p-6">Driver tidak ditemukan</div>;

  const user = driver.user || {};

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Detail Driver</h1>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Profile */}
        <div className="bg-white rounded-xl p-6 border border-gray-100 text-center lg:col-span-1">
          <div className="w-20 h-20 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
            <Car className="w-10 h-10 text-primary" />
          </div>
          <h2 className="text-xl font-bold">{user.fullname}</h2>
          <p className="text-gray-500 text-sm">Driver #{driver.id}</p>

          <div className="flex justify-center gap-4 my-4">
            <div className="text-center">
              <p className="text-2xl font-bold text-amber-500">{driver.rating?.toFixed(1)}</p>
              <p className="text-xs text-gray-500">Rating</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold">{driver.total_orders || 0}</p>
              <p className="text-xs text-gray-500">Pesanan</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold">{driver.total_reviews || 0}</p>
              <p className="text-xs text-gray-500">Ulasan</p>
            </div>
          </div>

          <div className="space-y-2 text-left">
            <div className="flex items-center gap-2 text-sm">
              <Phone size={16} className="text-gray-400" /> {user.phone}
            </div>
            <div className="flex items-center gap-2 text-sm">
              <Mail size={16} className="text-gray-400" /> {user.email || '-'}
            </div>
            <div className="flex items-center gap-2 text-sm">
              <Award size={16} className="text-gray-400" />
              {driver.is_premium ? 'Premium' : 'Reguler'}
            </div>
          </div>

          <div className="mt-4 space-y-2">
            <div className={`px-3 py-2 rounded-lg text-sm font-medium ${driver.verification_status === 'verified' ? 'bg-green-50 text-green-700' : driver.verification_status === 'rejected' ? 'bg-red-50 text-red-700' : 'bg-yellow-50 text-yellow-700'}`}>
              {driver.verification_status === 'verified' ? <>Terverifikasi</> : driver.verification_status === 'rejected' ? 'Ditolak' : 'Pending'}
            </div>
            <div className={`px-3 py-2 rounded-lg text-sm font-medium ${user.is_active ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
              {user.is_active ? 'Aktif' : 'Banned'}
            </div>
          </div>
        </div>

        {/* Documents & Vehicles */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-xl p-6 border border-gray-100">
            <h3 className="font-semibold mb-4">Dokumen</h3>
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500 border-b border-gray-100">
                  <th className="pb-2 font-medium">Tipe</th>
                  <th className="pb-2 font-medium">No. Dokumen</th>
                  <th className="pb-2 font-medium">Status</th>
                </tr>
              </thead>
              <tbody>
                {(driver.documents || []).map(doc => (
                  <tr key={doc.id} className="border-b border-gray-50">
                    <td className="py-3 font-medium">{doc.document_type?.toUpperCase()}</td>
                    <td className="py-3">{doc.document_number || '-'}</td>
                    <td className="py-3">
                      <span className={`inline-flex items-center gap-1 text-xs font-medium
                        ${doc.status === 'verified' ? 'text-green-600' : doc.status === 'rejected' ? 'text-red-600' : 'text-yellow-600'}`}>
                        {doc.status === 'verified' ? <CheckCircle size={14} /> : <XCircle size={14} />}
                        {doc.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="bg-white rounded-xl p-6 border border-gray-100">
            <h3 className="font-semibold mb-4">Kendaraan</h3>
            <div className="grid gap-3">
              {(driver.vehicles || []).map(v => (
                <div key={v.id} className="flex items-center gap-4 p-3 bg-gray-50 rounded-lg">
                  <Car className="text-primary" size={24} />
                  <div>
                    <p className="font-medium">{v.brand} {v.model} ({v.year})</p>
                    <p className="text-sm text-gray-500">{v.plate_number} - {v.color} - {v.capacity} kursi</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Recent Bookings */}
          <div className="bg-white rounded-xl p-6 border border-gray-100">
            <h3 className="font-semibold mb-4">Pesanan Terbaru</h3>
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500 border-b border-gray-100">
                  <th className="pb-2 font-medium">Kode</th>
                  <th className="pb-2 font-medium">Total</th>
                  <th className="pb-2 font-medium">Status</th>
                  <th className="pb-2 font-medium">Tanggal</th>
                </tr>
              </thead>
              <tbody>
                {(driver.bookings || []).map(b => (
                  <tr key={b.id} className="border-b border-gray-50">
                    <td className="py-3 font-medium">{b.booking_code}</td>
                    <td className="py-3">Rp {(b.total_price || 0).toLocaleString()}</td>
                    <td className="py-3">
                      <span className="px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700">{b.status}</span>
                    </td>
                    <td className="py-3">{new Date(b.created_at).toLocaleDateString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
