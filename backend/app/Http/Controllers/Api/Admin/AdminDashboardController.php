<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Driver;
use App\Models\Booking;
use App\Models\Withdrawal;
use App\Models\DriverDocument;
use Illuminate\Support\Facades\DB;

class AdminDashboardController extends Controller
{
    public function index()
    {
        $totalUsers = User::count();
        $totalCustomers = User::where('role', 'customer')->count();
        $totalDrivers = User::where('role', 'driver')->count();
        $verifiedDrivers = Driver::where('is_verified', true)->count();
        $pendingDrivers = Driver::where('verification_status', 'pending')->count();

        $totalBookings = Booking::count();
        $completedBookings = Booking::where('status', 'trip_completed')->count();
        $canceledBookings = Booking::where('status', 'cancelled')->count();

        $totalRevenue = Booking::where('status', 'trip_completed')->sum('total_price');
        $totalCommission = Booking::where('status', 'trip_completed')->sum('commission_amount');

        $pendingWithdrawals = Withdrawal::where('status', 'pending')->sum('amount');
        $totalWithdrawals = Withdrawal::where('status', 'completed')->sum('amount');

        $recentBookings = Booking::with(['customer', 'driver.user'])
            ->latest()->take(10)->get();

        $monthlyRevenue = Booking::where('status', 'trip_completed')
            ->whereYear('created_at', now()->year)
            ->selectRaw("strftime('%m', created_at) as month, SUM(total_price) as revenue")
            ->groupBy('month')->pluck('revenue', 'month');

        $topDrivers = Driver::with('user')
            ->orderBy('total_orders', 'desc')->take(10)->get();

        return response()->json([
            'success' => true,
            'data' => [
                'stats' => [
                    'total_users' => $totalUsers,
                    'total_customers' => $totalCustomers,
                    'total_drivers' => $totalDrivers,
                    'verified_drivers' => $verifiedDrivers,
                    'pending_verification' => $pendingDrivers,
                    'total_bookings' => $totalBookings,
                    'completed_bookings' => $completedBookings,
                    'canceled_bookings' => $canceledBookings,
                    'total_revenue' => $totalRevenue,
                    'total_commission' => $totalCommission,
                    'pending_withdrawals' => $pendingWithdrawals,
                    'total_withdrawals' => $totalWithdrawals,
                ],
                'recent_bookings' => $recentBookings,
                'monthly_revenue' => $monthlyRevenue,
                'top_drivers' => $topDrivers,
            ],
        ]);
    }
}
