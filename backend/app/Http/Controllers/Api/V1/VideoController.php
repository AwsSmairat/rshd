<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\UpdateVideoProgressRequest;
use App\Http\Resources\VideoResource;
use App\Models\Video;
use App\Services\ProgressService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VideoController extends Controller
{
    public function show(Request $request, Video $video): JsonResponse
    {
        $this->authorize('view', $video);

        $video->load('lesson.subject');

        if ($request->user()->isStudent()) {
            $video->load(['progress' => fn ($query) => $query->where('student_id', $request->user()->id)]);
        }

        return $this->successResource(new VideoResource($video));
    }

    public function updateProgress(
        UpdateVideoProgressRequest $request,
        Video $video,
        ProgressService $progressService,
    ): JsonResponse {
        $this->authorize('updateProgress', $video);

        $progress = $progressService->updateVideoProgress(
            $request->user(),
            $video,
            $request->validated(),
        );

        return $this->successResponse(
            $progress->only([
                'watched_seconds',
                'current_position',
                'completion_percentage',
                'replay_count',
                'last_watched_at',
            ]),
            'تم تحديث تقدم المشاهدة بنجاح.',
        );
    }
}
