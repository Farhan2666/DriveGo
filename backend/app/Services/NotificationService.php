<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Support\Facades\Http;

class NotificationService
{
    const FCM_URL = 'https://fcm.googleapis.com/fcm/send';

    public function send(int $userId, string $title, string $content, string $type = 'system', ?string $refType = null, ?int $refId = null): Notification
    {
        $notification = Notification::create([
            'user_id' => $userId,
            'title' => $title,
            'content' => $content,
            'notification_type' => $type,
            'reference_type' => $refType,
            'reference_id' => $refId,
        ]);

        $user = User::find($userId);
        if ($user && $user->fcm_token) {
            $this->sendFcm($user->fcm_token, $title, $content, $refType, $refId);
        }

        // Broadcast realtime via Node.js socket
        $this->broadcastRealtime($userId, $notification);

        return $notification;
    }

    public function sendToAllUsers(string $title, string $content, string $type = 'system', ?string $refType = null, ?int $refId = null): void
    {
        User::where('is_active', true)->chunk(100, function ($users) use ($title, $content, $type, $refType, $refId) {
            foreach ($users as $user) {
                $this->send($user->id, $title, $content, $type, $refType, $refId);
            }
        });
    }

    private function sendFcm(string $token, string $title, string $body, ?string $refType, ?int $refId): void
    {
        $payload = [
            'to' => $token,
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => 'default',
            ],
            'data' => [
                'type' => $refType,
                'reference_id' => (string) $refId,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
        ];

        Http::withHeaders([
            'Authorization' => 'key=' . config('services.fcm.server_key'),
            'Content-Type' => 'application/json',
        ])->post(self::FCM_URL, $payload);
    }

    private function broadcastRealtime(int $userId, Notification $notification): void
    {
        // Hit Node.js realtime server untuk broadcast via Socket.io
        Http::post(config('services.realtime.base_url') . '/broadcast', [
            'user_id' => $userId,
            'event' => 'notification',
            'data' => $notification->toArray(),
        ]);
    }
}
