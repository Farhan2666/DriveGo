<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Services\NotificationService;

class MessageController extends Controller
{
    public function __construct(private NotificationService $notif) {}

    public function index()
    {
        $user = auth()->user();
        $bookingId = request('booking_id');
        $otherId = request('other_user_id');

        $messages = Message::with('sender')
            ->when($bookingId, fn($q) => $q->where('booking_id', $bookingId))
            ->when($otherId, function ($q) use ($user, $otherId) {
                $q->where(function ($sub) use ($user, $otherId) {
                    $sub->where('sender_id', $user->id)->where('receiver_id', $otherId)
                        ->orWhere('sender_id', $otherId)->where('receiver_id', $user->id);
                });
            })
            ->orderBy('created_at', 'asc')
            ->paginate(request('per_page', 50));

        // Mark unread messages as read
        Message::unread($user->id)->whereIn('id', $messages->pluck('id'))->get()
            ->each(fn($m) => $m->markAsRead());

        return response()->json(['success' => true, 'data' => $messages]);
    }

    public function store()
    {
        $data = request()->validate([
            'receiver_id' => 'required|exists:users,id',
            'message' => 'required|string|max:1000',
            'booking_id' => 'nullable|exists:bookings,id',
            'message_type' => 'sometimes|in:text,image,location,system',
            'attachment_url' => 'nullable|string|max:500',
        ]);

        $message = Message::create([
            'sender_id' => auth()->id(),
            'receiver_id' => $data['receiver_id'],
            'message' => $data['message'],
            'booking_id' => $data['booking_id'] ?? null,
            'message_type' => $data['message_type'] ?? 'text',
            'attachment_url' => $data['attachment_url'] ?? null,
        ]);

        $this->notif->send(
            $data['receiver_id'],
            'Pesan Baru',
            auth()->user()->fullname . ': ' . substr($data['message'], 0, 100),
            'system', 'message', $message->id
        );

        return response()->json([
            'success' => true,
            'data' => $message->load('sender'),
        ], 201);
    }

    public function conversations()
    {
        $userId = auth()->id();
        $messageIds = Message::where('sender_id', $userId)
            ->orWhere('receiver_id', $userId)
            ->selectRaw('MAX(id) as id')
            ->groupBy(\DB::raw('CASE WHEN sender_id = ' . $userId . ' THEN receiver_id ELSE sender_id END'))
            ->pluck('id');

        $messages = Message::whereIn('id', $messageIds)
            ->with(['sender', 'receiver'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['success' => true, 'data' => $messages]);
    }
}
