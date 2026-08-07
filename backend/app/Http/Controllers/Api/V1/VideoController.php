<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\UpdateVideoProgressRequest;
use App\Http\Resources\VideoResource;
use App\Models\Video;
use App\Services\ProgressService;
use App\Services\VideoPlaybackService;
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

        return $this->playbackResponse(new VideoResource($video));
    }

    public function playback(Request $request, Video $video, VideoPlaybackService $playbackService): JsonResponse
    {
        $this->authorize('view', $video);

        $video->load('lesson.subject');

        $playback = $playbackService->generatePlaybackUrl($video, $request->user());

        if ($playback === null) {
            return $this->forbiddenResponse('غير مصرح لك بتشغيل هذا الفيديو.');
        }

        return $this->playbackResponse([
            'id' => $video->id,
            'playback' => [
                'url' => $playback['url'],
                'expires_at' => $playback['expires_at']->toIso8601String(),
            ],
        ]);
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

    protected function playbackResponse(mixed $data): JsonResponse
    {
        return $this->successResponse(
            $data instanceof VideoResource ? $data->resolve(request()) : $data,
        )->withHeaders([
            'Cache-Control' => 'private, no-store, no-cache, must-revalidate',
            'Pragma' => 'no-cache',
        ]);
    }
}
