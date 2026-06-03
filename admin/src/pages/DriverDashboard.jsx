import React, { useState } from 'react';
import { Car, MapPin, DollarSign, Clock } from 'lucide-react';

function DriverDashboard() {
  const [isOnline, setIsOnline] = useState(false);

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Halo, Mitra Driver!</h1>
        <button 
          onClick={() => setIsOnline(!isOnline)}
          className={px-4 py-2 rounded-lg font-medium text-white transition-colors  + (isOnline ? 'bg-red-500 hover:bg-red-600' : 'bg-green-500 hover:bg-green-600')}
        >
          {isOnline ? 'Offline' : 'Mulai Narik (Online)'}
        </button>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex items-center gap-4">
          <div className="w-12 h-12 bg-green-100 text-green-600 rounded-full flex items-center justify-center">
            <DollarSign size={24} />
          </div>
          <div>
            <p className="text-sm text-gray-500">Pendapatan Hari Ini</p>
            <p className="text-xl font-bold">Rp 0</p>
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex items-center gap-4">
          <div className="w-12 h-12 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center">
            <Clock size={24} />
          </div>
          <div>
            <p className="text-sm text-gray-500">Waktu Online</p>
            <p className="text-xl font-bold">0j 0m</p>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <h2 className="text-lg font-semibold mb-4">Pekerjaan Tersedia</h2>
        {isOnline ? (
          <div className="text-center py-8 text-gray-500">
            <div className="animate-pulse flex flex-col items-center">
              <MapPin className="w-10 h-10 text-primary mb-2 opacity-50" />
              <p>Mencari penumpang di sekitarmu...</p>
            </div>
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <p>Silakan online untuk mulai menerima pesanan</p>
          </div>
        )}
      </div>
    </div>
  );
}

export default DriverDashboard;
