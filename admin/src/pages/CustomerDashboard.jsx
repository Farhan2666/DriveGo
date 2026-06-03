import React from 'react';
import { Car, MapPin, Search } from 'lucide-react';

function CustomerDashboard() {
  return (
    <div className="p-6 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Halo, Penumpang!</h1>
      
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 mb-6">
        <h2 className="text-lg font-semibold mb-4">Mau pergi kemana hari ini?</h2>
        <div className="space-y-4">
          <div className="relative">
            <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input type="text" className="w-full pl-10 pr-4 py-3 bg-gray-50 border-transparent rounded-lg focus:bg-white focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Lokasi Penjemputan" />
          </div>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input type="text" className="w-full pl-10 pr-4 py-3 bg-gray-50 border-transparent rounded-lg focus:bg-white focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Tujuan" />
          </div>
          <button className="w-full bg-primary text-white py-3 rounded-lg font-medium hover:bg-primary/90 flex items-center justify-center gap-2">
            <Car size={20} />
            Cari Driver
          </button>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <h2 className="text-lg font-semibold mb-4">Riwayat Perjalanan</h2>
        <div className="text-center py-8 text-gray-500">
          <p>Belum ada perjalanan</p>
        </div>
      </div>
    </div>
  );
}

export default CustomerDashboard;
