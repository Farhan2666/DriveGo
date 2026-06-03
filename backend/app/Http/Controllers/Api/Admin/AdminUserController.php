<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Driver;
use App\Models\AuditLog;

class AdminUserController extends Controller
{
    public function customers()
    {
        $customers = User::where('role', 'customer')
            ->when(request('search'), fn($q) => $q->where(function($sub) {
                $s = request('search');
                $sub->where('fullname', 'like', "%{$s}%")
                    ->orWhere('phone', 'like', "%{$s}%");
            }))
            ->orderBy('created_at', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $customers]);
    }

    public function drivers()
    {
        $drivers = Driver::with('user', 'documents', 'wallet')
            ->when(request('verification_status'), fn($q) => $q->where('verification_status', request('verification_status')))
            ->when(request('is_verified'), fn($q) => $q->where('is_verified', request('is_verified')))
            ->when(request('search'), function ($q) {
                $s = request('search');
                $q->whereHas('user', fn($u) => $u->where('fullname', 'like', "%{$s}%")
                    ->orWhere('phone', 'like', "%{$s}%"));
            })
            ->orderBy('created_at', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $drivers]);
    }

    public function showDriver($id)
    {
        $driver = Driver::with(['user', 'vehicles', 'documents', 'wallet', 'bookings' => fn($q) => $q->latest()->limit(20)])
            ->findOrFail($id);

        return response()->json(['success' => true, 'data' => $driver]);
    }

    public function approveDriver($id)
    {
        $driver = Driver::findOrFail($id);
        $driver->update(['is_verified' => true, 'verification_status' => 'verified']);

        DriverDocument::where('driver_id', $id)->update(['status' => 'verified', 'verified_by' => auth()->id(), 'verified_at' => now()]);

        AuditLog::log('driver_approved', 'driver', $id, null, ['verification_status' => 'verified']);

        return response()->json(['success' => true, 'message' => 'Driver telah diverifikasi']);
    }

    public function rejectDriver($id)
    {
        $driver = Driver::findOrFail($id);
        $reason = request('reason', 'Dokumen tidak memenuhi syarat');

        $driver->update(['verification_status' => 'rejected']);

        DriverDocument::where('driver_id', $id)
            ->where('status', 'pending')
            ->update(['status' => 'rejected', 'rejection_reason' => $reason, 'verified_by' => auth()->id(), 'verified_at' => now()]);

        AuditLog::log('driver_rejected', 'driver', $id, null, ['verification_status' => 'rejected', 'reason' => $reason]);

        return response()->json(['success' => true, 'message' => 'Driver ditolak']);
    }

    public function banDriver($id)
    {
        $driver = Driver::findOrFail($id);
        $driver->user->update(['is_active' => false]);

        AuditLog::log('driver_banned', 'driver', $id);

        return response()->json(['success' => true, 'message' => 'Driver dibanned']);
    }

    public function unbanDriver($id)
    {
        $driver = Driver::findOrFail($id);
        $driver->user->update(['is_active' => true]);

        AuditLog::log('driver_unbanned', 'driver', $id);

        return response()->json(['success' => true, 'message' => 'Driver di-unban']);
    }

    public function suspendUser($id)
    {
        $user = User::findOrFail($id);
        $user->update(['is_active' => !$user->is_active]);

        $status = $user->is_active ? 'activated' : 'suspended';
        AuditLog::log("user_{$status}", 'user', $id);

        return response()->json([
            'success' => true,
            'message' => "User telah di-" . ($user->is_active ? 'aktifkan' : 'suspend'),
        ]);
    }
}
