<?php

namespace App\Services\Video;

use App\Enums\VideoStatus;
use App\Models\Video;
use App\Services\Bunny\BunnyCdnTokenSigner;
use App\Services\Bunny\BunnyStreamApiClient;
use App\Services\Bunny\BunnyStreamStatusMapper;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Throwable;

class VideoStorageAuditService
{
    public function __construct(
        protected BunnyStreamApiClient $bunnyApi,
        protected BunnyCdnTokenSigner $tokenSigner,
        protected BunnyStreamStatusMapper $statusMapper,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function audit(bool $verifyBunnyRemote = true, bool $verifyPlaybackHttp = true): array
    {
        $videos = Video::query()->orderBy('id')->get();
        $fileIndex = $this->buildFileIndex();
        $linkedPaths = $this->linkedPaths($videos);

        $inventory = [];
        $orphanFiles = [];
        $duplicateGroups = [];
        $inconsistent = [];

        foreach ($fileIndex['files'] as $path => $meta) {
            if (! in_array($path, $linkedPaths, true)) {
                $orphanFiles[] = [
                    'relative_path' => $this->redactPath($path),
                    'size_bytes' => $meta['size'],
                    'checksum_sha256' => $meta['checksum'],
                ];
            }
        }

        foreach ($fileIndex['checksum_groups'] as $checksum => $paths) {
            if (count($paths) > 1) {
                $duplicateGroups[] = [
                    'checksum_sha256' => $checksum,
                    'paths' => array_map(fn (string $p): string => $this->redactPath($p), $paths),
                ];
            }
        }

        foreach ($videos as $video) {
            $entry = $this->auditVideo(
                $video,
                $fileIndex,
                $verifyBunnyRemote,
                $verifyPlaybackHttp,
            );
            $inventory[] = $entry;

            if ($entry['inconsistent']) {
                $inconsistent[] = [
                    'video_id' => $video->id,
                    'reasons' => $entry['inconsistent_reasons'],
                ];
            }
        }

        $summary = $this->buildSummary($inventory, $orphanFiles, $duplicateGroups, $inconsistent);

        return [
            'summary' => $summary,
            'inventory' => $inventory,
            'orphan_files' => $orphanFiles,
            'duplicate_file_groups' => $duplicateGroups,
            'inconsistent_records' => $inconsistent,
            'storage_roots' => [
                'primary_disk' => Video::storageDiskName(),
                'legacy_disk' => Video::legacyPublicDiskName(),
            ],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    protected function auditVideo(
        Video $video,
        array $fileIndex,
        bool $verifyBunnyRemote,
        bool $verifyPlaybackHttp,
    ): array {
        $hasExternalId = filled($video->external_video_id);
        $localPresent = $video->hasLocalStoredFile();
        $localMeta = $this->resolveLocalMeta($video, $fileIndex);
        $missingSource = $this->hasMissingSource($video, $localPresent);
        $migratable = $this->isMigratable($video, $localPresent, $missingSource);
        $inconsistentReasons = $this->detectInconsistencies($video, $localPresent, $localMeta);
        $recoveryMatch = $missingSource
            ? $this->findStrongRecoveryMatch($video, $fileIndex['files'], $this->linkedPaths(Video::query()->whereKeyNot($video->id)->get()))
            : null;

        $bunnyRemote = null;
        if ($verifyBunnyRemote && $hasExternalId && $this->bunnyApi->isConfigured()) {
            $bunnyRemote = $this->probeBunnyRemote($video);
            if ($bunnyRemote['exists'] === false) {
                $inconsistentReasons[] = 'external_video_id not found on Bunny';
            }
            if ($bunnyRemote['exists'] === true && $video->status === VideoStatus::Ready && ! $bunnyRemote['playable']) {
                $inconsistentReasons[] = 'Bunny remote status not playable while local status is ready';
            }
        }

        $playback = null;
        if ($verifyPlaybackHttp && $hasExternalId && $video->status === VideoStatus::Ready) {
            $playback = $this->probeSignedPlayback($video);
            if (($playback['signed_http'] ?? null) !== '200') {
                $inconsistentReasons[] = 'signed Bunny playlist not HTTP 200';
            }
            if (($playback['unsigned_http'] ?? null) !== '403') {
                $inconsistentReasons[] = 'unsigned Bunny playlist not blocked with HTTP 403';
            }
        }

        $notMigratableReason = null;
        if (! $migratable) {
            $notMigratableReason = $this->notMigratableReason($video, $localPresent, $missingSource);
        }

        return [
            'video_id' => $video->id,
            'title' => $video->title,
            'provider' => $video->storage_provider ?: '(empty)',
            'status' => $video->status->value,
            'external_video_id_present' => $hasExternalId ? 'yes' : 'no',
            'local_source_present' => $localPresent ? 'yes' : 'no',
            'migratable' => $migratable ? 'yes' : 'no',
            'not_migratable_reason' => $notMigratableReason,
            'classification' => $this->classify($video, $localPresent, $missingSource, $migratable),
            'recorded_path' => $video->video_path ? $this->redactPath($video->video_path) : null,
            'original_file_name' => $video->original_file_name,
            'recorded_file_size' => $video->file_size,
            'actual_file_size' => $localMeta['size'] ?? null,
            'size_match' => $localMeta['size_match'] ?? null,
            'recovery_match' => $recoveryMatch,
            'bunny_remote' => $bunnyRemote,
            'playback_probe' => $playback,
            'inconsistent' => $inconsistentReasons !== [],
            'inconsistent_reasons' => $inconsistentReasons,
        ];
    }

    protected function classify(Video $video, bool $localPresent, bool $missingSource, bool $migratable): string
    {
        if ($missingSource) {
            return $video->status === VideoStatus::Failed
                ? 'MISSING_SOURCE_FAILED'
                : 'MISSING_SOURCE';
        }

        if ($video->status === VideoStatus::Failed && ! $localPresent && ! filled($video->external_video_id)) {
            return 'UNPLAYABLE_FAILED';
        }

        if (filled($video->external_video_id) && $video->status === VideoStatus::Ready) {
            return 'BUNNY_READY';
        }

        if (filled($video->external_video_id)) {
            return 'BUNNY_IN_PROGRESS';
        }

        if ($migratable) {
            return 'LOCAL_MIGRATABLE';
        }

        if (in_array($video->storage_provider, ['demo', ''], true) || $video->resolvedExternalVideoUrl() !== null) {
            return 'EXTERNAL_DEMO';
        }

        return 'NOT_MIGRATABLE';
    }

    protected function isMigratable(Video $video, bool $localPresent, bool $missingSource): bool
    {
        if (filled($video->external_video_id)) {
            return false;
        }

        if ($missingSource || ! $localPresent) {
            return false;
        }

        if ($video->video_path === null || $video->video_path === '') {
            return false;
        }

        return in_array($video->storage_provider, ['local', 'bunny', ''], true);
    }

    protected function hasMissingSource(Video $video, bool $localPresent): bool
    {
        if ($video->video_path === null || $video->video_path === '') {
            return false;
        }

        return ! $localPresent;
    }

    protected function notMigratableReason(Video $video, bool $localPresent, bool $missingSource): string
    {
        if (filled($video->external_video_id)) {
            return 'Already has Bunny external_video_id';
        }

        if ($missingSource) {
            return 'Recorded local source missing on disk (MISSING_SOURCE)';
        }

        if (! $localPresent) {
            return 'No local staging file';
        }

        if ($video->storage_provider === 'demo' || $video->resolvedExternalVideoUrl() !== null) {
            return 'Demo/external URL video';
        }

        return 'Not eligible for Bunny migration';
    }

    /**
     * @return list<string>
     */
    protected function detectInconsistencies(Video $video, bool $localPresent, array $localMeta): array
    {
        $reasons = [];
        $missingSource = $this->hasMissingSource($video, $localPresent);
        $reconciledMissing = $missingSource && $video->status === VideoStatus::Failed;
        $reconciledEmptyFailed = $video->status === VideoStatus::Failed
            && ! $localPresent
            && ! filled($video->external_video_id)
            && ($video->video_path === null || $video->video_path === '');

        if ($video->storage_provider === 'bunny'
            && ! filled($video->external_video_id)
            && $video->status !== VideoStatus::Failed) {
            $reasons[] = 'provider=bunny without external_video_id';
        }

        if (($video->storage_provider === '' || $video->storage_provider === null)
            && $video->status !== VideoStatus::Failed
            && ! filled($video->external_video_id)
            && ! $video->resolvedExternalVideoUrl()) {
            $reasons[] = 'storage_provider is empty';
        }

        if ($localPresent && isset($localMeta['size_match']) && $localMeta['size_match'] === false) {
            $reasons[] = 'recorded file_size does not match actual file';
        }

        if ($missingSource && ! $reconciledMissing) {
            $reasons[] = 'database path points to missing file';
        }

        if (filled($video->external_video_id) && $video->status === VideoStatus::Uploading) {
            $reasons[] = 'has external_video_id but status=uploading';
        }

        if ($reconciledEmptyFailed && ($video->storage_provider === '' || $video->storage_provider === null)) {
            // Empty provider on a reconciled failed empty record is acceptable.
        }

        return $reasons;
    }

    /**
     * @param  Collection<int, Video>  $videos
     * @return list<string>
     */
    protected function linkedPaths(Collection $videos): array
    {
        return $videos
            ->pluck('video_path')
            ->filter(fn (?string $path): bool => filled($path))
            ->values()
            ->all();
    }

    /**
     * @return array{files: array<string, array{size: int, checksum: string, disk: string}>, checksum_groups: array<string, list<string>>}
     */
    protected function buildFileIndex(): array
    {
        $files = [];
        $checksumGroups = [];

        foreach ([Video::storageDiskName(), Video::legacyPublicDiskName()] as $diskName) {
            if ($diskName === Video::storageDiskName() && $diskName === Video::legacyPublicDiskName()) {
                // same disk scanned once
            }

            $disk = Storage::disk($diskName);
            $all = $disk->allFiles();

            foreach ($all as $relativePath) {
                if (! $this->isVideoFile($relativePath)) {
                    continue;
                }

                if (isset($files[$relativePath])) {
                    continue;
                }

                $absolute = $disk->path($relativePath);
                $size = (int) $disk->size($relativePath);
                $checksum = hash_file('sha256', $absolute) ?: '';

                $files[$relativePath] = [
                    'size' => $size,
                    'checksum' => $checksum,
                    'disk' => $diskName,
                ];

                $checksumGroups[$checksum][] = $relativePath;
            }
        }

        return [
            'files' => $files,
            'checksum_groups' => $checksumGroups,
        ];
    }

    /**
     * @param  array<string, array{size: int, checksum: string, disk: string}>  $files
     * @param  list<string>  $linkedPaths
     * @return array<string, mixed>|null
     */
    protected function findStrongRecoveryMatch(Video $video, array $files, array $linkedPaths): ?array
    {
        $candidates = [];

        foreach ($files as $path => $meta) {
            if (in_array($path, $linkedPaths, true)) {
                continue;
            }

            $score = 0;
            $reasons = [];

            if ($video->original_file_name && basename($path) === $video->original_file_name) {
                $score += 100;
                $reasons[] = 'basename matches original_file_name';
            }

            if ($video->video_path && basename($video->video_path) === basename($path)) {
                $score += 100;
                $reasons[] = 'basename matches recorded path basename';
            }

            if ($video->file_size > 0 && $video->file_size === $meta['size']) {
                $score += 80;
                $reasons[] = 'exact file_size match';
            }

            if ($score >= 100) {
                $candidates[] = [
                    'relative_path' => $this->redactPath($path),
                    'score' => $score,
                    'reasons' => $reasons,
                    'size_bytes' => $meta['size'],
                ];
            }
        }

        if ($candidates === []) {
            return null;
        }

        usort($candidates, fn (array $a, array $b): int => $b['score'] <=> $a['score']);

        return $candidates[0];
    }

    /**
     * @return array{size: ?int, size_match: ?bool}
     */
    protected function resolveLocalMeta(Video $video, array $fileIndex): array
    {
        if ($video->video_path === null || $video->video_path === '') {
            return ['size' => null, 'size_match' => null];
        }

        $meta = $fileIndex['files'][$video->video_path] ?? null;

        if ($meta === null) {
            return ['size' => null, 'size_match' => null];
        }

        $sizeMatch = null;
        if ($video->file_size > 0) {
            $sizeMatch = $video->file_size === $meta['size'];
        }

        return [
            'size' => $meta['size'],
            'size_match' => $sizeMatch,
        ];
    }

    /**
     * @return array{exists: ?bool, remote_status: ?int, mapped_status: ?string, playable: ?bool}
     */
    protected function probeBunnyRemote(Video $video): array
    {
        try {
            $payload = $this->bunnyApi->getVideo((string) $video->external_video_id);
            $remoteStatus = (int) ($payload['status'] ?? -1);

            return [
                'exists' => true,
                'remote_status' => $remoteStatus,
                'mapped_status' => $this->statusMapper->fromApiStatus($remoteStatus)->value,
                'playable' => $remoteStatus === 4,
            ];
        } catch (Throwable) {
            return [
                'exists' => false,
                'remote_status' => null,
                'mapped_status' => null,
                'playable' => false,
            ];
        }
    }

    /**
     * @return array{signed_http: string, unsigned_http: string}
     */
    protected function probeSignedPlayback(Video $video): array
    {
        $cdnHost = rtrim((string) config('video.bunny.cdn_hostname'), '/');
        $tokenKey = (string) config('video.bunny.token_key');
        $guid = (string) $video->external_video_id;

        if ($cdnHost === '' || $tokenKey === '' || $guid === '') {
            return ['signed_http' => 'skipped', 'unsigned_http' => 'skipped'];
        }

        $unsigned = "https://{$cdnHost}/{$guid}/playlist.m3u8";
        $expires = now()->addSeconds(max(60, (int) config('video.playback_ttl', 600)))->getTimestamp();
        $signed = $this->tokenSigner->signUrl(
            url: $unsigned,
            securityKey: $tokenKey,
            expiresAt: $expires,
            isDirectory: true,
            pathAllowed: "/{$guid}/",
        );

        return [
            'signed_http' => $this->httpStatus($signed),
            'unsigned_http' => $this->httpStatus($unsigned),
        ];
    }

    protected function httpStatus(string $url): string
    {
        try {
            return (string) Http::timeout(20)->get($url)->status();
        } catch (Throwable) {
            return 'error';
        }
    }

    protected function isVideoFile(string $path): bool
    {
        return (bool) preg_match('/\.(mp4|mov|webm|m4v|mkv)$/i', $path);
    }

    protected function redactPath(string $path): string
    {
        return basename($path);
    }

    /**
     * @param  list<array<string, mixed>>  $inventory
     * @param  list<array<string, mixed>>  $orphanFiles
     * @param  list<array<string, mixed>>  $duplicateGroups
     * @param  list<array<string, mixed>>  $inconsistent
     * @return array<string, mixed>
     */
    protected function buildSummary(array $inventory, array $orphanFiles, array $duplicateGroups, array $inconsistent): array
    {
        $bunnyReady = 0;
        $localMigratable = 0;
        $missingSource = 0;

        foreach ($inventory as $item) {
            match ($item['classification']) {
                'BUNNY_READY' => $bunnyReady++,
                'LOCAL_MIGRATABLE' => $localMigratable++,
                'MISSING_SOURCE', 'MISSING_SOURCE_FAILED' => $missingSource++,
                default => null,
            };
        }

        $safeBatch = array_values(array_map(
            fn (array $item): int => $item['video_id'],
            array_filter($inventory, fn (array $item): bool => $item['classification'] === 'LOCAL_MIGRATABLE'),
        ));

        $needsRecovery = array_values(array_map(
            fn (array $item): int => $item['video_id'],
            array_filter(
                $inventory,
                fn (array $item): bool => in_array($item['classification'], ['MISSING_SOURCE'], true),
            ),
        ));

        return [
            'total_video_records' => count($inventory),
            'bunny_ready' => $bunnyReady,
            'local_migratable' => $localMigratable,
            'missing_source' => $missingSource,
            'orphan_files' => count($orphanFiles),
            'duplicate_file_groups' => count($duplicateGroups),
            'inconsistent_records' => count($inconsistent),
            'safe_batch_candidates' => $safeBatch,
            'needs_manual_recovery' => $needsRecovery,
            'storage_reconciliation' => count($inconsistent) === 0 ? 'PASS' : 'FAIL',
        ];
    }
}
