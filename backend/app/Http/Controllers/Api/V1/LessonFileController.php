<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreAnnotationRequest;
use App\Http\Resources\LessonFileResource;
use App\Models\LessonFile;
use App\Models\PdfAnnotation;
use App\Models\User;
use App\Services\LessonFileAccessService;
use App\Services\LessonFileDownloadService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class LessonFileController extends Controller
{
    public function show(LessonFile $lessonFile): JsonResponse
    {
        $this->authorize('view', $lessonFile);

        $lessonFile->load('lesson.subject');

        return $this->successResource(new LessonFileResource($lessonFile));
    }

    public function download(
        Request $request,
        LessonFile $lessonFile,
        LessonFileDownloadService $downloadService,
    ): JsonResponse {
        $this->authorize('view', $lessonFile);

        $lessonFile->load('lesson.subject');

        $download = $downloadService->generateDownloadUrl($lessonFile, $request->user());

        if ($download === null) {
            return $this->forbiddenResponse('غير مصرح لك بتنزيل هذا الملف.');
        }

        return $this->successResponse([
            'url' => $download['url'],
            'expires_at' => $download['expires_at']->toIso8601String(),
        ]);
    }

    public function stream(Request $request, LessonFile $lessonFile): StreamedResponse
    {
        if (! $request->hasValidSignature()) {
            abort(403, 'Download link is invalid or expired.');
        }

        $userId = (int) $request->query('uid');
        $user = $userId > 0 ? User::query()->find($userId) : null;

        if ($user === null || ! app(LessonFileAccessService::class)->canDownload($user, $lessonFile)) {
            abort(403, 'Download link is invalid or expired.');
        }

        $diskName = $lessonFile->localSourceDiskName();
        $path = (string) $lessonFile->file_path;

        if ($path === '' || ! Storage::disk($diskName)->exists($path)) {
            abort(404, 'File was not found.');
        }

        $mimeType = $lessonFile->file_mime_type ?: 'application/pdf';
        $filename = $lessonFile->original_file_name ?: basename($path);

        return Storage::disk($diskName)->response(
            $path,
            $filename,
            [
                'Content-Type' => $mimeType,
                'Cache-Control' => 'private, no-store, no-cache, must-revalidate',
                'Pragma' => 'no-cache',
            ],
        );
    }

    public function getAnnotations(Request $request, LessonFile $lessonFile): JsonResponse
    {
        $this->authorize('annotate', $lessonFile);

        $annotation = PdfAnnotation::query()
            ->where('student_id', $request->user()->id)
            ->where('file_id', $lessonFile->id)
            ->first();

        return $this->successResponse([
            'file_id' => $lessonFile->id,
            'annotation_json' => $annotation?->annotation_json ?? new \stdClass,
        ]);
    }

    public function storeAnnotations(
        StoreAnnotationRequest $request,
        LessonFile $lessonFile,
    ): JsonResponse {
        $this->authorize('annotate', $lessonFile);

        $annotation = PdfAnnotation::query()->updateOrCreate(
            [
                'student_id' => $request->user()->id,
                'file_id' => $lessonFile->id,
            ],
            [
                'annotation_json' => $request->validated('annotation_json'),
            ],
        );

        return $this->successResponse([
            'file_id' => $lessonFile->id,
            'annotation_json' => $annotation->annotation_json ?? new \stdClass,
        ], 'تم حفظ الملاحظات بنجاح.');
    }
}
