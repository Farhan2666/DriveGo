<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\FavoriteDriver;

class DriverController extends Controller
{
    public function index()
    {
        $drivers = Driver::verified()->available()
            ->with('user', 'vehicles')
            ->when(request('lat') && request('lng'), function ($q) {
                $q->nearby(request('lat'), request('lng'), request('radius', 10));
            })
            ->when(request('rating'), fn($q) => $q->where('rating', '>=', request('rating')))
            ->when(request('search'), function ($q) {
                $search = request('search');
                $q->whereHas('user', fn($u) => $u->where('fullname', 'like', "%{$search}%"));
            })
            ->when(request('plate_region'), function ($q) {
                $plate = request('plate_region');
                $q->whereHas('vehicles', fn($v) => $v->where('plate_number', 'like', "{$plate}%"));
            })
            ->orderBy('rating', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $drivers,
        ]);
    }

    public function search()
    {
        $lat = request('lat');
        $lng = request('lng');
        $destinationLat = request('dest_lat');
        $destinationLng = request('dest_lng');

        $drivers = Driver::verified()->available()
            ->with('user', 'vehicles')
            ->when($lat && $lng, fn($q) => $q->nearby($lat, $lng, request('radius', 10)))
            ->when(request('min_capacity'), function ($q) {
                $q->whereHas('vehicles', fn($v) => $v->where('capacity', '>=', request('min_capacity')));
            })
            ->get();

        if (auth()->check() && auth()->user()->role === 'customer') {
            $favoriteIds = FavoriteDriver::where('customer_id', auth()->id())
                ->pluck('driver_id')->toArray();

            $drivers->each(function ($d) use ($favoriteIds) {
                $d->is_favorite = in_array($d->id, $favoriteIds);
            });
        }

        return response()->json([
            'success' => true,
            'data' => $drivers,
        ]);
    }

    public function show($id)
    {
        $driver = Driver::with(['user', 'vehicles', 'reviews.customer'])->findOrFail($id);
        $driver->is_favorite = auth()->check() && auth()->user()->role === 'customer'
            ? FavoriteDriver::where('customer_id', auth()->id())->where('driver_id', $id)->exists()
            : false;

        return response()->json([
            'success' => true,
            'data' => $driver,
        ]);
    }

    public function updateAvailability()
    {
        request()->validate(['status' => 'required|in:online,offline,available,busy']);
        auth()->user()->driver->update(['availability_status' => request('status')]);

        return response()->json([
            'success' => true,
            'message' => 'Status availability diperbarui',
        ]);
    }

    public function updateLocation()
    {
        $data = request()->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
        ]);

        auth()->user()->driver->updateLocation($data['lat'], $data['lng']);

        return response()->json(['success' => true, 'message' => 'Lokasi diperbarui']);
    }

    public function statistics()
    {
        $driver = auth()->user()->driver;

        return response()->json([
            'success' => true,
            'data' => [
                'total_orders' => $driver->total_orders,
                'total_earnings' => $driver->total_earnings,
                'rating' => $driver->rating,
                'total_reviews' => $driver->total_reviews,
                'monthly_orders' => $driver->bookings()
                    ->whereMonth('created_at', now()->month)
                    ->whereYear('created_at', now()->year)
                    ->count(),
                'monthly_earnings' => $driver->bookings()
                    ->where('status', 'trip_completed')
                    ->whereMonth('created_at', now()->month)
                    ->whereYear('created_at', now()->year)
                    ->sum('total_price'),
            ],
        ]);
    }

    public function toggleFavorite($id)
    {
        $driver = Driver::findOrFail($id);
        $favorite = FavoriteDriver::where('customer_id', auth()->id())
            ->where('driver_id', $id)->first();

        if ($favorite) {
            $favorite->delete();
            $message = 'Driver dihapus dari favorit';
        } else {
            FavoriteDriver::create(['customer_id' => auth()->id(), 'driver_id' => $id]);
            $message = 'Driver ditambahkan ke favorit';
        }

        return response()->json(['success' => true, 'message' => $message]);
    }

    public function favorites()
    {
        $favorites = FavoriteDriver::where('customer_id', auth()->id())
            ->with('driver.user', 'driver.vehicles', 'driver.reviews')
            ->get()->pluck('driver');

        return response()->json(['success' => true, 'data' => $favorites]);
    }
}
