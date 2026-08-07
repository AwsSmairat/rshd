<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Video;
use App\Services\VideoAccessService;
use App\Services\VideoPlaybackService;
use App\Services\VideoStreamService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\StreamedResponse;

class VideoStreamController extends Controller
{
    public function stream(
        Request $request,
        Video $video,
        VideoPlaybackService $playbackService,
        VideoAccessService $accessService,
        VideoStreamService $streamService,
    ): Response|StreamedResponse|RedirectResponse {
        $userId = (int) $request->query('uid', 0);
        $expires = (int) $request->query('expires', 0);
        $token = (string) $request->query('token', '');

        if ($userId <= 0 || $expires <= 0 || $token === '') {
            abort(403, 'Invalid playback token.');
        }

        if (! $playbackService->validateLocalStreamToken($video, $userId, $expires, $token)) {
            abort(403, 'Playback token is invalid or expired.');
        }

        $user = User::query()->find($userId);

        if ($user === null || ! $accessService->canPlay($user, $video)) {
            abort(403, 'Playback is not authorized.');
        }

        if ($video->video_path === null || $video->video_path === '') {
            $externalUrl = $video->resolvedExternalVideoUrl();

            if ($externalUrl === null || $externalUrl === '') {
                abort(404, 'Video file was not found.');
            }

            return redirect()->away($externalUrl, 302, [
                'Cache-Control' => 'private, no-store, no-cache, must-revalidate',
                'Pragma' => 'no-cache',
            ]);
        }

        [$storage] = $streamService->resolveStorage($video);
        $mimeType = $video->file_mime_type ?: $storage->mimeType($video->video_path) ?: 'video/mp4';

        return $streamService->stream(
            $video,
            $request->header('Range'),
            $mimeType,
        );
    }
}
