<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\SubjectCategory;
use App\Http\Controllers\Controller;
use App\Http\Resources\SubjectResource;
use App\Models\Subject;
use App\Services\EnrollmentService;
use App\Services\PlatformSettingsService;
use App\Services\StudentLearningProgressService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SubjectController extends Controller
{
    public function mySubjects(
        Request $request,
        StudentLearningProgressService $progressService,
    ): JsonResponse {
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذا المسار متاح للطلاب فقط.');
        }

        $subjects = $user->enrolledSubjects()
            ->wherePivot('payment_status', PaymentStatus::Paid)
            ->wherePivot('access_status', AccessStatus::Active)
            ->where('subjects.status', ContentStatus::Active)
            ->with('instructor')
            ->get();

        $progressMap = [];

        try {
            $progressMap = $progressService->progressPercentMapForSubjects(
                $user,
                $subjects->pluck('id'),
            );
        } catch (\Throwable) {
            $progressMap = [];
        }

        $subjects->each(function (Subject $subject) use ($progressMap): void {
            $subject->setAttribute('enrollment_status', 'active');
            $subject->setAttribute(
                'progress_percent',
                $progressMap[$subject->id] ?? 0.0,
            );
        });

        return $this->successResourceList(SubjectResource::collection($subjects));
    }

    public function catalog(
        Request $request,
        EnrollmentService $enrollmentService,
        PlatformSettingsService $settings,
    ): JsonResponse {
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذا المسار متاح للطلاب فقط.');
        }

        $query = Subject::query()->with('instructor');

        if (! $settings->enabled('show_inactive_subjects', 'students')) {
            $query->where('status', ContentStatus::Active);
        }

        $category = $request->query('category');
        if (is_string($category) && $category !== '') {
            $valid = collect(SubjectCategory::cases())->contains(
                fn (SubjectCategory $case) => $case->value === $category,
            );

            if (! $valid) {
                return $this->errorResponse('تصنيف غير صالح.', 422);
            }

            $query->where('category', $category);
        }

        $subjects = $query->latest()->get()->each(function (Subject $subject) use ($user, $enrollmentService): void {
            $subject->setAttribute(
                'enrollment_status',
                $enrollmentService->enrollmentStatusFor($user, $subject),
            );
        });

        return $this->successResourceList(SubjectResource::collection($subjects));
    }

    public function purchaseRequest(
        Request $request,
        Subject $subject,
        EnrollmentService $enrollmentService,
        PlatformSettingsService $settings,
    ): JsonResponse {
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('طلبات الشراء متاحة للطلاب فقط.');
        }

        $enrollmentService->requestPurchase($user, $subject);

        $subject->load('instructor');
        $subject->setAttribute('enrollment_status', 'pending');

        return $this->successResponse([
            'subject' => (new SubjectResource($subject))->resolve($request),
            'payment_instructions' => $settings->stringValue(
                'payment_instructions',
                '',
                'payments',
            ),
        ], 'تم إرسال طلب الشراء. بانتظار تفعيل الإدارة.', 201);
    }
}
