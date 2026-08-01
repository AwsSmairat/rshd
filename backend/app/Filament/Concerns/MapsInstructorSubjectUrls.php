<?php

namespace App\Filament\Concerns;

use App\Filament\Resources\AssignmentResource;
use App\Filament\Resources\LessonFileResource;
use App\Filament\Resources\LessonResource;
use App\Filament\Resources\QuizResource;
use App\Filament\Resources\SubjectResource;
use App\Filament\Resources\VideoResource;

trait MapsInstructorSubjectUrls
{
    public function subjectsIndexUrl(): string
    {
        return SubjectResource::getUrl('index');
    }

    public function subjectEditUrl(int|string $subjectId): string
    {
        return SubjectResource::getUrl('edit', ['record' => $subjectId]);
    }

    public function subjectLessonsUrl(int|string $subjectId): string
    {
        return $this->resourceIndexWithSubjectFilter(LessonResource::class, $subjectId);
    }

    public function subjectVideosUrl(int|string $subjectId): string
    {
        return $this->resourceIndexWithSubjectFilter(VideoResource::class, $subjectId);
    }

    public function subjectAssignmentsUrl(int|string $subjectId): string
    {
        return $this->resourceIndexWithSubjectFilter(AssignmentResource::class, $subjectId);
    }

    public function subjectQuizzesUrl(int|string $subjectId): string
    {
        return $this->resourceIndexWithSubjectFilter(QuizResource::class, $subjectId);
    }

    public function subjectFilesUrl(int|string $subjectId): string
    {
        return $this->resourceIndexWithSubjectFilter(LessonFileResource::class, $subjectId);
    }

    /**
     * @param  class-string  $resourceClass
     */
    protected function resourceIndexWithSubjectFilter(string $resourceClass, int|string $subjectId): string
    {
        return $resourceClass::getUrl('index', [
            'tableFilters' => [
                'subject_id' => ['value' => (string) $subjectId],
            ],
        ]);
    }
}
