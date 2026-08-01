<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\AccessStatus;
use App\Enums\AnnouncementTargetType;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\AnnouncementResource;
use App\Models\Announcement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AnnouncementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذا المسار متاح للطلاب فقط.');
        }

        $subjectIds = $user->enrolledSubjects()
            ->wherePivot('payment_status', PaymentStatus::Paid)
            ->wherePivot('access_status', AccessStatus::Active)
            ->pluck('subjects.id');

        $announcements = Announcement::query()
            ->with('subject')
            ->where(function ($query) use ($subjectIds) {
                $query->where('target_type', AnnouncementTargetType::All)
                    ->orWhere(function ($subjectQuery) use ($subjectIds) {
                        $subjectQuery
                            ->where('target_type', AnnouncementTargetType::Subject)
                            ->whereIn('subject_id', $subjectIds);
                    });
            })
            ->latest()
            ->get();

        return $this->successResourceList(AnnouncementResource::collection($announcements));
    }
}
