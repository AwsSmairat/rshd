<?php

namespace App\Services\LessonFiles;

use App\Enums\LessonFileStorageStatus;
use App\Models\LessonFile;
use Illuminate\Support\Facades\Storage;

class LessonFileStorageAuditService
{
    /**
     * @return array<string, mixed>
     */
    public function audit(): array
    {
        $records = LessonFile::query()->get();

        $publicPdfFiles = [];
        $permanentPublicUrls = [];
        $inconsistent = [];

        foreach ($records as $file) {
            if ($this->isPublicDeliverySource($file)) {
                $publicPdfFiles[] = [
                    'file_id' => $file->id,
                    'file_path' => $file->file_path,
                    'file_url' => $file->file_url,
                ];
            }

            if ($this->hasPermanentPublicUrl($file)) {
                $permanentPublicUrls[] = [
                    'file_id' => $file->id,
                    'file_url' => $file->file_url,
                ];
            }

            $reasons = $this->inconsistencyReasons($file);
            if ($reasons !== []) {
                $inconsistent[] = [
                    'file_id' => $file->id,
                    'reasons' => $reasons,
                ];
            }
        }

        $localOrphans = $this->findLocalOrphans($records);

        return [
            'summary' => [
                'total_records' => $records->count(),
                'public_pdf_files' => count($publicPdfFiles),
                'permanent_public_urls' => count($permanentPublicUrls),
                'local_orphan_files' => count($localOrphans),
                'inconsistent_records' => count($inconsistent),
            ],
            'public_pdf_files' => $publicPdfFiles,
            'permanent_public_urls' => $permanentPublicUrls,
            'local_orphan_files' => $localOrphans,
            'inconsistent_records' => $inconsistent,
        ];
    }

    protected function isPublicDeliverySource(LessonFile $file): bool
    {
        if ($file->storage_provider === 'bunny') {
            return false;
        }

        if ($file->file_type?->value !== 'pdf') {
            return false;
        }

        if ($file->file_path && str_starts_with($file->file_path, 'lesson-files/')) {
            return Storage::disk('public')->exists($file->file_path);
        }

        return false;
    }

    protected function hasPermanentPublicUrl(LessonFile $file): bool
    {
        if ($file->requiresSignedDownload()) {
            return false;
        }

        $url = $file->file_url;
        if ($url === null || $url === '') {
            return false;
        }

        if (str_starts_with($url, 'http://') || str_starts_with($url, 'https://')) {
            return ! str_contains($url, 'token=');
        }

        return str_contains($url, '/storage/');
    }

    /**
     * @return list<string>
     */
    protected function inconsistencyReasons(LessonFile $file): array
    {
        $reasons = [];

        if ($file->storage_provider === 'bunny') {
            if (! filled($file->external_path)) {
                $reasons[] = 'bunny provider without external_path';
            }

            if ($file->storage_status !== LessonFileStorageStatus::Ready) {
                $reasons[] = 'bunny provider status is not ready';
            }

            if (filled($file->file_url) && ! str_starts_with((string) $file->file_url, 'http')) {
                $reasons[] = 'bunny record exposes local file_url';
            }

            if ($file->file_path && Storage::disk('public')->exists($file->file_path)) {
                $reasons[] = 'bunny record still has public local source';
            }
        }

        return $reasons;
    }

    /**
     * @return list<array{relative_path: string, size_bytes: int}>
     */
    protected function findLocalOrphans($records): array
    {
        $linkedPublic = $records
            ->filter(fn (LessonFile $file) => $file->file_path && $file->storage_disk !== 'lesson_files')
            ->pluck('file_path')
            ->map(fn ($path) => basename((string) $path))
            ->all();

        $orphans = [];
        $publicDir = storage_path('app/public/lesson-files');

        if (! is_dir($publicDir)) {
            return [];
        }

        foreach (glob($publicDir.'/*') ?: [] as $absolute) {
            if (! is_file($absolute)) {
                continue;
            }

            $name = basename($absolute);
            if (in_array($name, $linkedPublic, true)) {
                continue;
            }

            $orphans[] = [
                'relative_path' => 'lesson-files/'.$name,
                'size_bytes' => filesize($absolute) ?: 0,
            ];
        }

        return $orphans;
    }
}
