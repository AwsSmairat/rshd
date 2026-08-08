<?php

namespace App\Services;

use App\Enums\ContentStatus;
use App\Enums\VideoStatus;
use App\Models\Assignment;
use App\Models\AssignmentSubmission;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Models\User;
use App\Models\Video;
use App\Models\VideoWatchProgress;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class StudentLearningProgressService
{
    public const VIDEO_COMPLETION_THRESHOLD = 80.0;

    private const SUBJECT_LEVEL_LESSON_KEY = 0;

    /**
     * Progress is averaged per lesson (part): each part with countable content
     * contributes equally. When all existing parts are fully completed → 100%.
     * When a new part with content is added, the percentage recalculates downward.
     *
     * @param  Collection<int, int>  $subjectIds
     * @return array<int, float>
     */
    public function progressPercentMapForSubjects(User $student, Collection $subjectIds): array
    {
        if ($subjectIds->isEmpty()) {
            return [];
        }

        $ids = $subjectIds->values()->all();
        $buckets = $this->buildLessonBuckets($student->id, $ids);

        $progressMap = [];

        foreach ($ids as $subjectId) {
            $partPercents = [];

            foreach ($buckets as $bucket) {
                if ($bucket['subject_id'] !== $subjectId || $bucket['total'] === 0) {
                    continue;
                }

                $partPercents[] = ($bucket['completed'] / $bucket['total']) * 100;
            }

            $progressMap[$subjectId] = $partPercents === []
                ? 0.0
                : round(array_sum($partPercents) / count($partPercents), 1);
        }

        return $progressMap;
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<string, array{subject_id: int, lesson_id: int, total: int, completed: int}>
     */
    private function buildLessonBuckets(int $studentId, array $subjectIds): array
    {
        $buckets = [];

        $this->mergeLessonCounts(
            $buckets,
            $this->videoTotalsByLesson($subjectIds),
            'total',
        );
        $this->mergeLessonCounts(
            $buckets,
            $this->completedVideosByLesson($studentId, $subjectIds),
            'completed',
        );
        $this->mergeLessonCounts(
            $buckets,
            $this->assignmentTotalsByLesson($subjectIds),
            'total',
        );
        $this->mergeLessonCounts(
            $buckets,
            $this->completedAssignmentsByLesson($studentId, $subjectIds),
            'completed',
        );
        $this->mergeLessonCounts(
            $buckets,
            $this->quizTotalsByLesson($subjectIds),
            'total',
        );
        $this->mergeLessonCounts(
            $buckets,
            $this->completedQuizzesByLesson($studentId, $subjectIds),
            'completed',
        );

        return $buckets;
    }

    /**
     * @param  array<string, array{subject_id: int, lesson_id: int, total: int, completed: int}>  $buckets
     * @param  array<string, int>  $counts
     */
    private function mergeLessonCounts(array &$buckets, array $counts, string $field): void
    {
        foreach ($counts as $key => $count) {
            if (! isset($buckets[$key])) {
                [$subjectId, $lessonId] = array_map('intval', explode(':', $key, 2));
                $buckets[$key] = [
                    'subject_id' => $subjectId,
                    'lesson_id' => $lessonId,
                    'total' => 0,
                    'completed' => 0,
                ];
            }

            $buckets[$key][$field] += $count;
        }
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<string, int>
     */
    private function videoTotalsByLesson(array $subjectIds): array
    {
        return Video::query()
            ->join('lessons', 'videos.lesson_id', '=', 'lessons.id')
            ->whereIn('lessons.subject_id', $subjectIds)
            ->where('lessons.status', ContentStatus::Active)
            ->where('videos.status', VideoStatus::Ready)
            ->groupBy('lessons.subject_id', 'lessons.id')
            ->selectRaw('lessons.subject_id as subject_id, lessons.id as lesson_id, COUNT(videos.id) as total')
            ->get()
            ->mapWithKeys(fn ($row): array => [
                $this->lessonBucketKey((int) $row->subject_id, (int) $row->lesson_id) => (int) $row->total,
            ])
            ->all();
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<string, int>
     */
    private function completedVideosByLesson(int $studentId, array $subjectIds): array
    {
        return VideoWatchProgress::query()
            ->join('videos', 'video_watch_progress.video_id', '=', 'videos.id')
            ->join('lessons', 'videos.lesson_id', '=', 'lessons.id')
            ->where('video_watch_progress.student_id', $studentId)
            ->where('video_watch_progress.completion_percentage', '>=', self::VIDEO_COMPLETION_THRESHOLD)
            ->whereIn('lessons.subject_id', $subjectIds)
            ->where('lessons.status', ContentStatus::Active)
            ->where('videos.status', VideoStatus::Ready)
            ->groupBy('lessons.subject_id', 'lessons.id')
            ->selectRaw('lessons.subject_id as subject_id, lessons.id as lesson_id, COUNT(DISTINCT videos.id) as total')
            ->get()
            ->mapWithKeys(fn ($row): array => [
                $this->lessonBucketKey((int) $row->subject_id, (int) $row->lesson_id) => (int) $row->total,
            ])
            ->all();
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<string, int>
     */
    private function assignmentTotalsByLesson(array $subjectIds): array
    {
        return Assignment::query()
            ->leftJoin('lessons', 'assignments.lesson_id', '=', 'lessons.id')
            ->whereIn('assignments.subject_id', $subjectIds)
            ->where('assignments.status', ContentStatus::Active)
            ->where(function ($query): void {
                $query->whereNull('assignments.lesson_id')
                    ->orWhere('lessons.status', ContentStatus::Active);
            })
            ->groupBy('assignments.subject_id', DB::raw('COALESCE(assignments.lesson_id, '.self::SUBJECT_LEVEL_LESSON_KEY.')'))
            ->selectRaw(
                'assignments.subject_id as subject_id, COALESCE(assignments.lesson_id, '
                .self::SUBJECT_LEVEL_LESSON_KEY.') as lesson_id, COUNT(assignments.id) as total',
            )
            ->get()
            ->mapWithKeys(fn ($row): array => [
                $this->lessonBucketKey((int) $row->subject_id, (int) $row->lesson_id) => (int) $row->total,
            ])
            ->all();
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<string, int>
     */
    private function completedAssignmentsByLesson(int $studentId, array $subjectIds): array
    {
        return AssignmentSubmission::query()
            ->join('assignments', 'assignment_submissions.assignment_id', '=', 'assignments.id')
            ->leftJoin('lessons', 'assignments.lesson_id', '=', 'lessons.id')
            ->where('assignment_submissions.student_id', $studentId)
            ->whereIn('assignments.subject_id', $subjectIds)
            ->where('assignments.status', ContentStatus::Active)
            ->where(function ($query): void {
                $query->whereNull('assignments.lesson_id')
                    ->orWhere('lessons.status', ContentStatus::Active);
            })
            ->groupBy('assignments.subject_id', DB::raw('COALESCE(assignments.lesson_id, '.self::SUBJECT_LEVEL_LESSON_KEY.')'))
            ->selectRaw(
                'assignments.subject_id as subject_id, COALESCE(assignments.lesson_id, '
                .self::SUBJECT_LEVEL_LESSON_KEY.') as lesson_id, COUNT(DISTINCT assignments.id) as total',
            )
            ->get()
            ->mapWithKeys(fn ($row): array => [
                $this->lessonBucketKey((int) $row->subject_id, (int) $row->lesson_id) => (int) $row->total,
            ])
            ->all();
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<string, int>
     */
    private function quizTotalsByLesson(array $subjectIds): array
    {
        return Quiz::query()
            ->leftJoin('lessons', 'quizzes.lesson_id', '=', 'lessons.id')
            ->whereIn('quizzes.subject_id', $subjectIds)
            ->where('quizzes.status', ContentStatus::Active)
            ->where(function ($query): void {
                $query->whereNull('quizzes.lesson_id')
                    ->orWhere('lessons.status', ContentStatus::Active);
            })
            ->groupBy('quizzes.subject_id', DB::raw('COALESCE(quizzes.lesson_id, '.self::SUBJECT_LEVEL_LESSON_KEY.')'))
            ->selectRaw(
                'quizzes.subject_id as subject_id, COALESCE(quizzes.lesson_id, '
                .self::SUBJECT_LEVEL_LESSON_KEY.') as lesson_id, COUNT(quizzes.id) as total',
            )
            ->get()
            ->mapWithKeys(fn ($row): array => [
                $this->lessonBucketKey((int) $row->subject_id, (int) $row->lesson_id) => (int) $row->total,
            ])
            ->all();
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<string, int>
     */
    private function completedQuizzesByLesson(int $studentId, array $subjectIds): array
    {
        return QuizAttempt::query()
            ->join('quizzes', 'quiz_attempts.quiz_id', '=', 'quizzes.id')
            ->leftJoin('lessons', 'quizzes.lesson_id', '=', 'lessons.id')
            ->where('quiz_attempts.student_id', $studentId)
            ->whereNotNull('quiz_attempts.submitted_at')
            ->whereIn('quizzes.subject_id', $subjectIds)
            ->where('quizzes.status', ContentStatus::Active)
            ->where(function ($query): void {
                $query->whereNull('quizzes.lesson_id')
                    ->orWhere('lessons.status', ContentStatus::Active);
            })
            ->groupBy('quizzes.subject_id', DB::raw('COALESCE(quizzes.lesson_id, '.self::SUBJECT_LEVEL_LESSON_KEY.')'))
            ->selectRaw(
                'quizzes.subject_id as subject_id, COALESCE(quizzes.lesson_id, '
                .self::SUBJECT_LEVEL_LESSON_KEY.') as lesson_id, COUNT(DISTINCT quizzes.id) as total',
            )
            ->get()
            ->mapWithKeys(fn ($row): array => [
                $this->lessonBucketKey((int) $row->subject_id, (int) $row->lesson_id) => (int) $row->total,
            ])
            ->all();
    }

    private function lessonBucketKey(int $subjectId, int $lessonId): string
    {
        return "{$subjectId}:{$lessonId}";
    }
}
