<?php

namespace App\Services;

use App\Models\Video;
use Illuminate\Contracts\Filesystem\Filesystem;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\StreamedResponse;

class VideoStreamService
{
    /**
     * @return array{0: Filesystem, 1: string}
     */
    public function resolveStorage(Video $video): array
    {
        $path = $video->video_path;

        if ($path === null || $path === '') {
            abort(404, 'Video file was not found.');
        }

        $primaryDisk = (string) config('video.local.disk', 'lesson_videos');
        $primary = Storage::disk($primaryDisk);

        if ($primary->exists($path)) {
            return [$primary, $path];
        }

        $legacyDisk = (string) config('video.legacy_public_disk', 'public');

        if ($primaryDisk !== $legacyDisk) {
            $legacy = Storage::disk($legacyDisk);

            if ($legacy->exists($path)) {
                return [$legacy, $path];
            }
        }

        abort(404, 'Video file was not found.');
    }

    public function stream(Video $video, ?string $rangeHeader, string $mimeType): StreamedResponse
    {
        [$storage, $path] = $this->resolveStorage($video);
        $absolutePath = $storage->path($path);
        $fileSize = $storage->size($path);

        $start = 0;
        $end = $fileSize - 1;
        $status = Response::HTTP_OK;

        if ($rangeHeader !== null && preg_match('/bytes=(\d*)-(\d*)/', $rangeHeader, $matches) === 1) {
            if ($matches[1] !== '') {
                $start = (int) $matches[1];
            }

            if ($matches[2] !== '') {
                $end = (int) $matches[2];
            }

            if ($start > $end || $start >= $fileSize) {
                return response()->stream(static function (): void {}, Response::HTTP_REQUESTED_RANGE_NOT_SATISFIABLE, [
                    'Content-Range' => 'bytes */'.$fileSize,
                    'Accept-Ranges' => 'bytes',
                ]);
            }

            $end = min($end, $fileSize - 1);
            $status = Response::HTTP_PARTIAL_CONTENT;
        }

        $length = $end - $start + 1;

        $headers = [
            'Content-Type' => $mimeType,
            'Content-Length' => (string) $length,
            'Accept-Ranges' => 'bytes',
            'Cache-Control' => 'private, no-store, no-cache, must-revalidate',
            'Pragma' => 'no-cache',
        ];

        if ($status === Response::HTTP_PARTIAL_CONTENT) {
            $headers['Content-Range'] = 'bytes '.$start.'-'.$end.'/'.$fileSize;
        }

        return response()->stream(
            function () use ($absolutePath, $start, $length): void {
                $handle = fopen($absolutePath, 'rb');

                if ($handle === false) {
                    return;
                }

                fseek($handle, $start);

                $remaining = $length;
                $chunkSize = 8192;

                while ($remaining > 0 && ! feof($handle)) {
                    $readLength = min($chunkSize, $remaining);
                    $buffer = fread($handle, $readLength);

                    if ($buffer === false) {
                        break;
                    }

                    echo $buffer;
                    $remaining -= strlen($buffer);
                }

                fclose($handle);
            },
            $status,
            $headers,
        );
    }
}
