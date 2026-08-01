<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notifications = $request->user()
            ->notifications()
            ->latest()
            ->get();

        return $this->successResourceList(NotificationResource::collection($notifications));
    }

    public function markAsRead(Request $request, AppNotification $notification): JsonResponse
    {
        if ($notification->user_id !== $request->user()->id) {
            return $this->forbiddenResponse();
        }

        $notification->update(['is_read' => true]);

        return $this->successResource(
            new NotificationResource($notification->fresh()),
            'تم تعليم الإشعار كمقروء.',
        );
    }
}
