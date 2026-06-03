<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmergencySos;
use App\Services\NotificationService;

class EmergencyController extends Controller
{
    public function __construct(private NotificationService $notif) {}

    public function sos()
    {
        $data = request()->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
            'booking_id' => 'nullable|exists:bookings,id',
        ]);

        $sos = EmergencySos::create([
            'user_id' => auth()->id(),
            'booking_id' => $data['booking_id'] ?? null,
            'lat' => $data['lat'],
            'lng' => $data['lng'],
        ]);

        // Notify admin
        $admin = \App\Models\User::where('role', 'admin')->first();
        if ($admin) {
            $this->notif->send(
                $admin->id,
                'SOS Darurat!',
                "Pengguna {$sos->user->fullname} mengirim sinyal SOS di ({$data['lat']}, {$data['lng']})",
                'emergency', 'sos', $sos->id
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Sinyal SOS terkirim. Tim kami akan segera menghubungi Anda.',
            'data' => $sos,
        ], 201);
    }

    public function resolve($id)
    {
        $sos = EmergencySos::findOrFail($id);
        $sos->resolve();

        return response()->json(['success' => true, 'message' => 'SOS di-resolve']);
    }

    public function active()
    {
        $sos = EmergencySos::where('status', 'active')->with('user', 'booking')->get();
        return response()->json(['success' => true, 'data' => $sos]);
    }
}
