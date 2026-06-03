<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Review;

class ReviewController extends Controller
{
    public function store()
    {
        $data = request()->validate([
            'booking_id' => 'required|exists:bookings,id',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $booking = Booking::where('customer_id', auth()->id())
            ->where('status', 'trip_completed')
            ->findOrFail($data['booking_id']);

        if ($booking->review) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah memberikan review untuk booking ini',
            ], 400);
        }

        $review = Review::create([
            'booking_id' => $booking->id,
            'customer_id' => auth()->id(),
            'driver_id' => $booking->driver_id,
            'rating' => $data['rating'],
            'comment' => $data['comment'] ?? null,
        ]);

        $booking->driver->updateRating();

        return response()->json([
            'success' => true,
            'message' => 'Review berhasil dikirim',
            'data' => $review,
        ], 201);
    }

    public function index()
    {
        $reviews = Review::with('customer', 'booking')
            ->when(request('driver_id'), fn($q) => $q->where('driver_id', request('driver_id')))
            ->when(request('rating'), fn($q) => $q->where('rating', request('rating')))
            ->orderBy('created_at', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $reviews]);
    }

    public function show($id)
    {
        $review = Review::with('customer', 'driver.user')->findOrFail($id);
        return response()->json(['success' => true, 'data' => $review]);
    }
}
