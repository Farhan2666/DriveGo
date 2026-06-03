<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Withdrawal;
use App\Models\Payment;
use Illuminate\Support\Facades\DB;

class AdminFinanceController extends Controller
{
    public function transactions()
    {
        $transactions = Booking::with(['customer', 'driver.user', 'payment'])
            ->when(request('status'), fn($q) => $q->where('status', request('status')))
            ->when(request('date_from'), fn($q) => $q->whereDate('created_at', '>=', request('date_from')))
            ->when(request('date_to'), fn($q) => $q->whereDate('created_at', '<=', request('date_to')))
            ->orderBy('created_at', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $transactions]);
    }

    public function withdrawals()
    {
        $withdrawals = Withdrawal::with(['driver.user', 'processor'])
            ->when(request('status'), fn($q) => $q->where('status', request('status')))
            ->orderBy('created_at', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $withdrawals]);
    }

    public function approveWithdrawal($id)
    {
        $withdrawal = Withdrawal::where('status', 'pending')->findOrFail($id);
        $withdrawal->approve(auth()->id());

        return response()->json(['success' => true, 'message' => 'Withdrawal disetujui']);
    }

    public function rejectWithdrawal($id)
    {
        $withdrawal = Withdrawal::where('status', 'pending')->findOrFail($id);
        $reason = request('reason', 'Ditolak oleh admin');
        $withdrawal->reject(auth()->id(), $reason);

        return response()->json(['success' => true, 'message' => 'Withdrawal ditolak']);
    }

    public function reports()
    {
        $type = request('type', 'daily');
        $date = request('date', now()->format('Y-m-d'));

        $query = Booking::where('status', 'trip_completed');

        $groupBy = match ($type) {
            'daily' => "date(created_at)",
            'monthly' => "strftime('%Y-%m', created_at)",
            'yearly' => "strftime('%Y', created_at)",
            default => "date(created_at)",
        };

        $report = $query->selectRaw("
            {$groupBy} as period,
            COUNT(*) as total_bookings,
            SUM(total_price) as total_revenue,
            SUM(commission_amount) as total_commission,
            AVG(total_price) as avg_order_value
        ")->groupBy('period')->orderBy('period', 'desc')
            ->when($type === 'daily', fn($q) => $q->whereDate('created_at', $date))
            ->get();

        $paymentSummary = Payment::selectRaw("
            payment_method,
            COUNT(*) as total,
            SUM(amount) as total_amount
        ")->groupBy('payment_method')->get();

        return response()->json([
            'success' => true,
            'data' => [
                'report' => $report,
                'payment_summary' => $paymentSummary,
            ],
        ]);
    }
}
