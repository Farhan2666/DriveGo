<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\BookingRequest;
use App\Models\Booking;
use App\Models\Driver;
use App\Services\PricingService;
use App\Services\MapService;
use App\Services\NotificationService;
use Illuminate\Support\Str;

class BookingController extends Controller
{
    public function __construct(
        private PricingService $pricing,
        private MapService $map,
        private NotificationService $notif
    ) {}

    public function store(BookingRequest $request)
    {
        $driver = Driver::findOrFail($request->driver_id);

        if (!$driver->is_verified || $driver->availability_status !== 'available') {
            return response()->json([
                'success' => false,
                'message' => 'Driver tidak tersedia',
            ], 400);
        }

        $distance = $this->map->calculateDistance(
            ['lat' => $request->pickup_lat, 'lng' => $request->pickup_lng],
            ['lat' => $request->dest_lat, 'lng' => $request->dest_lng]
        );

        $price = $this->pricing->calculatePrice($distance['distance_km'] ?? 0);

        if ($request->voucher_code) {
            $voucherResult = $this->pricing->applyVoucher($price['total_price'], $request->voucher_code);
            $price['total_price'] = $voucherResult['total_price'];
            $price['voucher_discount'] = $voucherResult['voucher_discount'];
        }

        $booking = Booking::create([
            'booking_code' => 'DG-' . strtoupper(Str::random(10)),
            'customer_id' => auth()->id(),
            'driver_id' => $driver->id,
            'vehicle_id' => $request->vehicle_id ?? $driver->vehicles()->first()?->id,
            'pickup_location' => $request->pickup_location,
            'pickup_lat' => $request->pickup_lat,
            'pickup_lng' => $request->pickup_lng,
            'destination' => $request->destination,
            'dest_lat' => $request->dest_lat,
            'dest_lng' => $request->dest_lng,
            'booking_date' => $request->booking_date,
            'booking_time' => $request->booking_time,
            'total_distance_km' => $distance['distance_km'] ?? null,
            'estimated_duration_min' => $distance['duration_min'] ?? null,
            'base_price' => $price['base_price'],
            'distance_price' => $price['distance_price'],
            'service_fee' => $price['service_fee'],
            'commission_amount' => $price['commission_amount'],
            'voucher_discount' => $price['voucher_discount'] ?? 0,
            'total_price' => $price['total_price'],
            'status' => 'waiting_payment',
        ]);

        $driver->update(['availability_status' => 'busy']);

        $this->notif->send(
            $driver->user_id,
            'Pesanan Baru',
            "Ada pesanan baru dari {$booking->customer->fullname}",
            'booking', 'booking', $booking->id
        );

        return response()->json([
            'success' => true,
            'message' => 'Booking berhasil dibuat',
            'data' => $booking->load('driver.user', 'vehicle'),
        ], 201);
    }

    public function index()
    {
        $user = auth()->user();

        $bookings = Booking::with(['driver.user', 'vehicle', 'payment', 'review'])
            ->when($user->role === 'customer', fn($q) => $q->where('customer_id', $user->id))
            ->when($user->role === 'driver', fn($q) => $q->where('driver_id', $user->driver->id))
            ->when(request('status'), fn($q) => $q->where('status', request('status')))
            ->when(request('date_from'), fn($q) => $q->whereDate('booking_date', '>=', request('date_from')))
            ->when(request('date_to'), fn($q) => $q->whereDate('booking_date', '<=', request('date_to')))
            ->orderBy('created_at', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $bookings]);
    }

    public function show($id)
    {
        $booking = Booking::with([
            'customer', 'driver.user', 'vehicle',
            'payment', 'review', 'tracking',
            'messages' => fn($q) => $q->latest()->limit(50),
        ])->findOrFail($id);

        $this->authorizeAccess($booking);

        return response()->json(['success' => true, 'data' => $booking]);
    }

    public function update($id)
    {
        $booking = Booking::findOrFail($id);
        $this->authorizeAccess($booking);

        $action = request('action');

        match ($action) {
            'confirm' => $this->confirm($booking),
            'pickup' => $this->pickup($booking),
            'start_trip' => $this->startTrip($booking),
            'complete' => $this->complete($booking),
            'cancel' => $this->cancel($booking),
            default => throw new \InvalidArgumentException('Action tidak dikenal'),
        };

        return response()->json([
            'success' => true,
            'message' => 'Status booking diperbarui',
            'data' => $booking->fresh()->load('driver.user', 'payment'),
        ]);
    }

    private function confirm(Booking $booking): void
    {
        $booking->update(['status' => 'driver_confirmed']);
        $this->notif->send($booking->customer_id, 'Driver Dikonfirmasi',
            "Driver {$booking->driver->user->fullname} telah mengkonfirmasi pesanan Anda",
            'booking', 'booking', $booking->id);
    }

    private function pickup(Booking $booking): void
    {
        $booking->update(['status' => 'customer_picked_up']);
    }

    private function startTrip(Booking $booking): void
    {
        $booking->update(['status' => 'trip_started', 'started_at' => now()]);
    }

    private function complete(Booking $booking): void
    {
        $booking->update(['status' => 'trip_completed', 'completed_at' => now()]);
        $booking->driver->update(['availability_status' => 'available']);
        $booking->driver->increment('total_orders');

        $commissionAmount = $booking->total_price * 0.10;
        $driverAmount = $booking->total_price - $commissionAmount;

        if ($booking->driver->wallet) {
            $booking->driver->wallet->addBalance(
                $driverAmount, 'commission', $booking,
                "Pembayaran booking {$booking->booking_code}"
            );
        }
    }

    private function cancel(Booking $booking): void
    {
        $reason = request('reason', 'Dibatalkan oleh pengguna');
        $by = auth()->user()->role === 'customer' ? 'customer' : 'driver';

        $booking->cancel($reason, $by);
        $booking->driver?->update(['availability_status' => 'available']);
    }

    public function calculatePrice()
    {
        $data = request()->validate([
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'dest_lat' => 'required|numeric',
            'dest_lng' => 'required|numeric',
            'voucher_code' => 'nullable|string',
        ]);

        $distance = $this->map->calculateDistance(
            ['lat' => $data['pickup_lat'], 'lng' => $data['pickup_lng']],
            ['lat' => $data['dest_lat'], 'lng' => $data['dest_lng']]
        );

        $price = $this->pricing->calculatePrice($distance['distance_km'] ?? 0);

        if ($data['voucher_code'] ?? false) {
            $result = $this->pricing->applyVoucher($price['total_price'], $data['voucher_code']);
            $price = array_merge($price, $result);
        }

        return response()->json([
            'success' => true,
            'data' => array_merge($price, [
                'distance_km' => $distance['distance_km'] ?? 0,
                'duration_min' => $distance['duration_min'] ?? 0,
            ]),
        ]);
    }

    public function history()
    {
        $user = auth()->user();
        $query = Booking::with(['driver.user', 'vehicle', 'review']);

        if ($user->role === 'customer') {
            $query->where('customer_id', $user->id);
        } else {
            $query->where('driver_id', $user->driver->id);
        }

        $bookings = $query->whereIn('status', ['trip_completed', 'cancelled', 'refund'])
            ->orderBy('created_at', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $bookings]);
    }

    private function authorizeAccess(Booking $booking): void
    {
        $user = auth()->user();
        if ($user->role === 'customer' && $booking->customer_id !== $user->id) {
            abort(403, 'Anda tidak punya akses ke booking ini');
        }
        if ($user->role === 'driver' && $booking->driver_id !== $user->driver->id) {
            abort(403, 'Anda tidak punya akses ke booking ini');
        }
    }
}
