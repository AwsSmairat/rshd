<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\ContentStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\LessonResource;
use App\Models\Lesson;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LessonController extends Controller
{
    public function index(Request $request, Subject $subject): JsonResponse
    {
        $this->authorize('view', $subject);

        $user = $request->user();

        $lessons = $subject->lessons()
            ->where('status', ContentStatus::Active)
            // Treat invalid/zero order values as "last" to avoid breaking UI ordering.
            ->orderByRaw('CASE WHEN `order` <= 0 THEN 999999999 ELSE `order` END')
            ->orderBy('id')
            ->with($this->lessonRelationsFor($user))
            ->get();

        $lessons->each(fn (Lesson $lesson) => $this->linkParents($lesson, $subject));

        return $this->successResourceList(LessonResource::collection($lessons));
    }

    public function show(Request $request, Lesson $lesson): JsonResponse
    {
        $this->authorize('view', $lesson);

        $lesson->load(array_merge(
            ['subject'],
            $this->lessonRelationsFor($request->user()),
        ));

        return $this->successResource(new LessonResource($lesson));
    }

    /**
     * Policies and resources call loadMissing('lesson.subject') on every nested
     * video, file, assignment and quiz. The subject is already known here, so
     * handing it down turns each of those lazy loads into a no-op.
     */
    private function linkParents(Lesson $lesson, Subject $subject): void
    {
        $subjectSummary = $subject->withoutRelations();
        $lesson->setRelation('subject', $subjectSummary);

        $lessonSummary = $lesson->withoutRelations();
        $lessonSummary->setRelation('subject', $subjectSummary);

        foreach (['videos', 'files'] as $relation) {
            $lesson->getRelation($relation)->each(
                fn (Model $child) => $child->setRelation('lesson', $lessonSummary)
            );
        }

        foreach (['assignments', 'quizzes'] as $relation) {
            $lesson->getRelation($relation)->each(
                fn (Model $child) => $child->setRelation('subject', $subjectSummary)
            );
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function lessonRelationsFor(?User $user): array
    {
        $relations = [
            'videos',
            'files',
            'assignments' => fn ($query) => $query
                ->where('status', ContentStatus::Active)
                ->orderBy('due_date')
                ->orderBy('id'),
            'quizzes' => fn ($query) => $query
                ->where('status', ContentStatus::Active)
                ->withCount('questions')
                ->orderBy('id'),
        ];

        if ($user?->isStudent()) {
            $relations['assignments'] = fn ($query) => $query
                ->where('status', ContentStatus::Active)
                ->orderBy('due_date')
                ->orderBy('id')
                ->with([
                    'submissions' => fn ($submissionQuery) => $submissionQuery
                        ->where('student_id', $user->id),
                ]);
            $relations['quizzes'] = fn ($query) => $query
                ->where('status', ContentStatus::Active)
                ->withCount('questions')
                ->orderBy('id')
                ->with([
                    'attempts' => fn ($attemptQuery) => $attemptQuery
                        ->where('student_id', $user->id)
                        ->orderByDesc('started_at')
                        ->limit(1),
                ]);
        }

        return $relations;
    }
}
