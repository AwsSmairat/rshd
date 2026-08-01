<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\SubmitAssignmentRequest;
use App\Http\Resources\AssignmentResource;
use App\Http\Resources\AssignmentSubmissionResource;
use App\Models\Assignment;
use App\Models\AssignmentSubmission;
use App\Services\PlatformNotificationService;
use App\Services\PlatformSettingsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AssignmentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Assignment::class);

        $user = $request->user();

        if ($user->isStudent()) {
            $subjectIds = $user->enrolledSubjects()
                ->wherePivot('payment_status', PaymentStatus::Paid)
                ->wherePivot('access_status', AccessStatus::Active)
                ->pluck('subjects.id');

            $assignments = Assignment::query()
                ->whereIn('subject_id', $subjectIds)
                ->where('status', ContentStatus::Active)
                ->with(['subject', 'lesson', 'submissions' => fn ($query) => $query->where('student_id', $user->id)])
                ->get();
        } elseif ($user->isInstructor()) {
            $assignments = Assignment::query()
                ->whereHas('subject', fn ($query) => $query->where('instructor_id', $user->id))
                ->with(['subject', 'lesson'])
                ->get();
        } else {
            $assignments = Assignment::query()
                ->with(['subject', 'lesson'])
                ->get();
        }

        return $this->successResourceList(AssignmentResource::collection($assignments));
    }

    public function submit(
        SubmitAssignmentRequest $request,
        Assignment $assignment,
        PlatformSettingsService $settings,
        PlatformNotificationService $notifications,
    ): JsonResponse {
        $this->authorize('submit', $assignment);

        $validated = $request->validated();
        $studentId = $request->user()->id;

        $submission = AssignmentSubmission::query()->firstOrNew([
            'assignment_id' => $assignment->id,
            'student_id' => $studentId,
        ]);

        if ($submission->exists && $submission->submitted_at !== null
            && ! $settings->enabled('allow_assignment_resubmission', 'students')) {
            return $this->errorResponse('إعادة تسليم الواجب غير مسموحة.', 422);
        }

        if (array_key_exists('answer_text', $validated)) {
            $answerText = trim((string) ($validated['answer_text'] ?? ''));
            $submission->answer_text = $answerText !== '' ? $answerText : null;
        }

        if ($request->hasFile('file')) {
            if ($submission->file_path) {
                Storage::disk('public')->delete($submission->file_path);
            }

            $uploadedFile = $request->file('file');
            $extension = $uploadedFile->getClientOriginalExtension();
            $filename = Str::uuid().($extension !== '' ? '.'.$extension : '');
            $directory = "assignment-submissions/{$studentId}/{$assignment->id}";
            $path = $uploadedFile->storeAs($directory, $filename, 'public');

            $submission->file_path = $path;
            $submission->file_url = Storage::disk('public')->url($path);
            $submission->original_file_name = $uploadedFile->getClientOriginalName();
            $submission->file_size = $uploadedFile->getSize();
            $submission->file_mime_type = $uploadedFile->getMimeType();
        }

        $submission->submitted_at = now();
        $submission->save();

        $assignment->loadMissing('subject.instructor');
        $instructor = $assignment->subject?->instructor;

        if ($instructor !== null) {
            $notifications->notifyUser(
                user: $instructor,
                title: 'تسليم واجب جديد',
                body: 'قام الطالب «'.$request->user()->name.'» بتسليم واجب «'.$assignment->title.'».',
                type: 'assignment_submitted',
                settingKey: 'notify_instructor_assignment_submitted',
                userPreferenceKey: 'notify_submissions',
            );
        }

        return $this->successResponse(
            AssignmentSubmissionResource::make($submission->fresh()),
            'تم تسليم الواجب بنجاح.',
        );
    }
}
