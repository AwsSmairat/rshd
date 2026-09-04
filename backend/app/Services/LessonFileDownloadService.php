<?php

namespace App\Services;

use App\Models\LessonFile;
use App\Models\User;
use App\Services\Bunny\BunnyFilesCdnTokenSigner;
use App\Support\SafeLogger;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use RuntimeException;

class LessonFileDownloadService
{
    public function __construct(
        protected LessonFileAccessService $access,
        protected BunnyFilesCdnTokenSigner $signer,
    ) {}

    /**
     * @return array{url: string, expires_at: Carbon}|null
     */
    public function generateDownloadUrl(LessonFile $lessonFile, User $user): ?array
    {
        if (! $this->access->canDownload($user, $lessonFile)) {
            return null;
        }

        if (! $this->access->isReadyForDownload($lessonFile)) {
            return null;
        }

        if ($lessonFile->file_type?->needsPdfPreview() && filled($lessonFile->file_path)) {
            return $this->generateLocalSignedUrl($lessonFile, $user);
        }

        if ($lessonFile->isBunnyStored()) {
            return $this->generateBunnySignedUrl($lessonFile);
        }

        if (filled($lessonFile->file_path)) {
            return $this->generateLocalSignedUrl($lessonFile, $user);
        }

        return null;
    }

    /**
     * @return array{url: string, expires_at: Carbon}|null
     */
    protected function generateLocalSignedUrl(LessonFile $lessonFile, User $user): ?array
    {
        $diskName = $lessonFile->localSourceDiskName();
        $path = (string) $lessonFile->file_path;

        if ($path === '' || ! Storage::disk($diskName)->exists($path)) {
            SafeLogger::warning('lesson_file.download.local_missing', [
                'file_id' => $lessonFile->id,
                'disk' => $diskName,
                'path' => $path,
            ]);

            return null;
        }

        $ttl = (int) config('files.download_ttl', 600);
        $expiresAt = now()->addSeconds($ttl);

        return [
            'url' => URL::temporarySignedRoute(
                'api.v1.files.stream',
                $expiresAt,
                [
                    'file' => $lessonFile->id,
                    'uid' => $user->id,
                ],
            ),
            'expires_at' => $expiresAt,
        ];
    }

    /**
     * @return array{url: string, expires_at: Carbon}
     */
    protected function generateBunnySignedUrl(LessonFile $lessonFile): ?array
    {
        if (! config('files.signed_download', true) || ! $this->signer->isConfigured()) {
            SafeLogger::warning('lesson_file.download.bunny_not_configured', [
                'file_id' => $lessonFile->id,
            ]);

            return null;
        }

        $externalPath = (string) $lessonFile->external_path;
        $ttl = (int) config('files.download_ttl', 600);
        $expiresAt = time() + $ttl;

        try {
            $signedUrl = $this->signer->signCdnPath($externalPath, $expiresAt);
        } catch (RuntimeException $exception) {
            SafeLogger::warning('lesson_file.download.sign_failed', [
                'file_id' => $lessonFile->id,
                'reason' => $exception->getMessage(),
            ]);

            return null;
        }

        return [
            'url' => $signedUrl,
            'expires_at' => Carbon::createFromTimestamp($expiresAt),
        ];
    }
}
