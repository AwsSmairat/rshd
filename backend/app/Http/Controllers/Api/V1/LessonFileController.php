<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreAnnotationRequest;
use App\Http\Resources\LessonFileResource;
use App\Models\LessonFile;
use App\Models\PdfAnnotation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LessonFileController extends Controller
{
    public function show(LessonFile $lessonFile): JsonResponse
    {
        $this->authorize('view', $lessonFile);

        $lessonFile->load('lesson.subject');

        return $this->successResource(new LessonFileResource($lessonFile));
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
