<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;

class NotificationController extends Controller
{
    public function index()
    {
        $notifications = Notification::where('user_id', auth()->id())
            ->orderBy('created_at', 'desc')
            ->paginate(request('per_page', 20));

        return response()->json(['success' => true, 'data' => $notifications]);
    }

    public function markAsRead($id)
    {
        $notif = Notification::where('user_id', auth()->id())->findOrFail($id);
        $notif->markAsRead();

        return response()->json(['success' => true, 'message' => 'Notifikasi dibaca']);
    }

    public function markAllAsRead()
    {
        Notification::where('user_id', auth()->id())->where('is_read', false)
            ->update(['is_read' => true, 'read_at' => now()]);

        return response()->json(['success' => true, 'message' => 'Semua notifikasi dibaca']);
    }

    public function unreadCount()
    {
        $count = Notification::where('user_id', auth()->id())->where('is_read', false)->count();

        return response()->json(['success' => true, 'data' => ['unread_count' => $count]]);
    }
}
