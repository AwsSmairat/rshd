<?php

namespace App\Services\LessonFiles;

use App\Enums\FileType;
use App\Models\LessonFile;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class LessonFilePdfPreviewService
{
    public function __construct(
        protected OfficeToPdfConverter $converter,
    ) {}

    public function absolutePdfPath(LessonFile $lessonFile): string
    {
        $diskName = $lessonFile->localSourceDiskName();
        $sourcePath = (string) $lessonFile->file_path;

        if ($sourcePath === '' || ! Storage::disk($diskName)->exists($sourcePath)) {
            throw new RuntimeException('الملف غير موجود.');
        }

        $sourceAbsolute = Storage::disk($diskName)->path($sourcePath);

        if ($lessonFile->file_type === FileType::Pdf) {
            return $sourceAbsolute;
        }

        if (! $lessonFile->file_type?->needsPdfPreview()) {
            return $sourceAbsolute;
        }

        $previewRelative = $this->previewRelativePath($lessonFile);

        if (Storage::disk('lesson_files')->exists($previewRelative)) {
            $previewAbsolute = Storage::disk('lesson_files')->path($previewRelative);

            if (filemtime($previewAbsolute) >= filemtime($sourceAbsolute)) {
                return $previewAbsolute;
            }
        }

        Storage::disk('lesson_files')->makeDirectory(dirname($previewRelative));
        $previewAbsolute = Storage::disk('lesson_files')->path($previewRelative);
        $extension = pathinfo($lessonFile->original_file_name ?: $sourcePath, PATHINFO_EXTENSION)
            ?: ($lessonFile->file_type === FileType::Ppt ? 'ppt' : 'doc');

        // Convert aside and swap in, so a failed or interrupted conversion can
        // never leave a truncated PDF cached under the final name.
        $stagingPath = $previewAbsolute.'.'.bin2hex(random_bytes(8)).'.part';

        try {
            $this->converter->convert($sourceAbsolute, $stagingPath, $extension);

            if (! is_file($stagingPath) || filesize($stagingPath) === 0) {
                throw new RuntimeException('تعذر تجهيز الملف للعرض داخل التطبيق.');
            }

            if (! rename($stagingPath, $previewAbsolute)) {
                throw new RuntimeException('تعذر حفظ نسخة العرض.');
            }
        } finally {
            if (is_file($stagingPath)) {
                @unlink($stagingPath);
            }
        }

        $this->forgetStalePreviews($lessonFile, $previewRelative);

        return $previewAbsolute;
    }

    /**
     * Keeps one preview per lesson file; earlier fingerprints are orphaned
     * whenever the source or its metadata changes.
     */
    protected function forgetStalePreviews(LessonFile $lessonFile, string $keepRelative): void
    {
        $disk = Storage::disk('lesson_files');

        foreach ($disk->files('previews') as $path) {
            if ($path === $keepRelative) {
                continue;
            }

            if (str_starts_with(basename($path), $lessonFile->id.'-')) {
                $disk->delete($path);
            }
        }
    }

    public function previewRelativePath(LessonFile $lessonFile): string
    {
        $fingerprint = sha1(implode('|', [
            (string) $lessonFile->id,
            (string) $lessonFile->file_path,
            (string) $lessonFile->file_size,
            (string) optional($lessonFile->updated_at)?->timestamp,
        ]));

        return 'previews/'.$lessonFile->id.'-'.$fingerprint.'.pdf';
    }
}
