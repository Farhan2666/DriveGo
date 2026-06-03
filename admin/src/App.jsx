import React, { useState } from 'react';
import { Routes, Route, Navigate, Link, useLocation } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import {
  LayoutDashboard, Users, Car, CreditCard, FileText,
  Bell, Settings, LogOut, Menu, X, ShieldAlert,
} from 'lucide-react';

import Dashboard from './pages/Dashboard';
import Customers from './pages/Customers';
import Drivers from './pages/Drivers';
import DriverDetail from './pages/DriverDetail';
import Transactions from './pages/Transactions';
import Withdrawals from './pages/Withdrawals';
import Reports from './pages/Reports';
import Login from './pages/Login';
import Register from './pages/Register';
import CustomerDashboard from './pages/CustomerDashboard';
import DriverDashboard from './pages/DriverDashboard';

const sidebarLinks = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/customers', icon: Users, label: 'Customer' },
  { to: '/drivers', icon: Car, label: 'Driver' },
  { to: '/transactions', icon: CreditCard, label: 'Transaksi' },
  { to: '/withdrawals', icon: FileText, label: 'Withdrawal' },
  { to: '/reports', icon: FileText, label: 'Laporan' },
];

function App() {
  const [isAuth, setIsAuth] = useState(localStorage.getItem('admin_token'));
  const [role, setRole] = useState(localStorage.getItem('user_role') || 'admin');
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('user_role');
    setIsAuth(false);
    setRole(null);
  };

  const handleLogin = (r) => {
    setIsAuth(true);
    setRole(r || 'admin');
  };

  if (!isAuth) {
    return (
      <>
        <Toaster position="top-right" />
        <Routes>
          <Route path="/register" element={<Register />} />
          <Route path="*" element={<Login onLogin={() => handleLogin()} />} />
        </Routes>
      </>
    );
  }

  // --- ADMIN PORTAL ---
  if (role === 'admin') {
    return (
      <div className="flex h-screen bg-gray-50">
        <Toaster position="top-right" />
        <aside className={(sidebarOpen ? 'w-64' : 'w-16') + " bg-gray-900 text-white transition-all duration-300 flex flex-col"}>
          <div className="p-4 flex items-center gap-3 border-b border-white/10">
            <Car className="w-8 h-8 text-primary" />
            {sidebarOpen && <span className="font-bold text-lg">DriveGo Admin</span>}
            <button onClick={() => setSidebarOpen(!sidebarOpen)} className="ml-auto text-gray-400 hover:text-white">
              {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
          </div>
          <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
            {sidebarLinks.map(l => (
              <SidebarLink key={l.to} to={l.to} icon={l.icon} label={l.label} collapsed={!sidebarOpen} />
            ))}
          </nav>
          <div className="p-3 border-t border-white/10">
            <button onClick={handleLogout} className="sidebar-link w-full">
              <LogOut size={20} />
              {sidebarOpen && <span>Logout</span>}
            </button>
          </div>
        </aside>

        <main className="flex-1 overflow-y-auto">
          <Routes>
            <Route path="/" element={<Navigate to="/dashboard" />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/customers" element={<Customers />} />
            <Route path="/drivers" element={<Drivers />} />
            <Route path="/drivers/:id" element={<DriverDetail />} />
            <Route path="/transactions" element={<Transactions />} />
            <Route path="/withdrawals" element={<Withdrawals />} />
            <Route path="/reports" element={<Reports />} />
            <Route path="*" element={<Navigate to="/dashboard" />} />
          </Routes>
        </main>
      </div>
    );
  }

  // --- CUSTOMER / DRIVER PORTAL ---
  return (
    <div className="min-h-screen bg-gray-50">
      <Toaster position="top-right" />
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-4xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2 text-primary font-bold text-xl">
            <Car /> DriveGo {role === 'driver' ? 'Driver' : 'User'}
          </div>
          <button onClick={handleLogout} className="flex items-center gap-2 text-red-500 hover:text-red-600 font-medium">
            <LogOut size={20} /> Keluar
          </button>
        </div>
      </header>
      <main>
        <Routes>
          <Route path="/" element={role === 'driver' ? <DriverDashboard /> : <CustomerDashboard />} />
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </main>
    </div>
  );
}

function SidebarLink({ to, icon: Icon, label, collapsed }) {
  const location = useLocation();
  const isActive = location.pathname.startsWith(to);
  return (
    <Link to={to} className={"sidebar-link " + (isActive ? 'active' : '')}>
      <Icon size={20} />
      {!collapsed && <span>{label}</span>}
    </Link>
  );
}

export default App;


