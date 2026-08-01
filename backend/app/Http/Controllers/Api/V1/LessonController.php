<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\ContentStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\LessonResource;
use App\Models\Lesson;
use App\Models\Subject;
use Illuminate\Http\JsonResponse;

class LessonController extends Controller
{
    public function index(Subject $subject): JsonResponse
    {
        $this->authorize('view', $subject);

        $lessons = $subject->lessons()
            ->where('status', ContentStatus::Active)
            // Treat invalid/zero order values as "last" to avoid breaking UI ordering.
            ->orderByRaw('CASE WHEN `order` <= 0 THEN 999999999 ELSE `order` END')
            ->orderBy('id')
            ->with(['videos', 'files'])
            ->get();

        return $this->successResourceList(LessonResource::collection($lessons));
    }

    public function show(Lesson $lesson): JsonResponse
    {
        $this->authorize('view', $lesson);

        $lesson->load(['subject', 'videos', 'files']);

        return $this->successResource(new LessonResource($lesson));
    }
}
