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

class StudentLearningProgressService
{
    public const VIDEO_COMPLETION_THRESHOLD = 80.0;

    /**
     * @param  Collection<int, int>  $subjectIds
     * @return array<int, float>
     */
    public function progressPercentMapForSubjects(User $student, Collection $subjectIds): array
    {
        if ($subjectIds->isEmpty()) {
            return [];
        }

        $ids = $subjectIds->values()->all();

        $videoTotals = $this->videoTotalsBySubject($ids);
        $completedVideos = $this->completedVideosBySubject($student->id, $ids);
        $assignmentTotals = $this->assignmentTotalsBySubject($ids);
        $completedAssignments = $this->completedAssignmentsBySubject($student->id, $ids);
        $quizTotals = $this->quizTotalsBySubject($ids);
        $completedQuizzes = $this->completedQuizzesBySubject($student->id, $ids);

        $progressMap = [];

        foreach ($ids as $subjectId) {
            $total = ($videoTotals[$subjectId] ?? 0)
                + ($assignmentTotals[$subjectId] ?? 0)
                + ($quizTotals[$subjectId] ?? 0);

            if ($total === 0) {
                $progressMap[$subjectId] = 0.0;

                continue;
            }

            $completed = ($completedVideos[$subjectId] ?? 0)
                + ($completedAssignments[$subjectId] ?? 0)
                + ($completedQuizzes[$subjectId] ?? 0);

            $progressMap[$subjectId] = round(($completed / $total) * 100, 1);
        }

        return $progressMap;
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<int, int>
     */
    private function videoTotalsBySubject(array $subjectIds): array
    {
        return Video::query()
            ->join('lessons', 'videos.lesson_id', '=', 'lessons.id')
            ->whereIn('lessons.subject_id', $subjectIds)
            ->where('videos.status', VideoStatus::Ready)
            ->groupBy('lessons.subject_id')
            ->selectRaw('lessons.subject_id as subject_id, COUNT(videos.id) as total')
            ->pluck('total', 'subject_id')
            ->map(fn ($count): int => (int) $count)
            ->all();
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<int, int>
     */
    private function completedVideosBySubject(int $studentId, array $subjectIds): array
    {
        return VideoWatchProgress::query()
            ->join('videos', 'video_watch_progress.video_id', '=', 'videos.id')
            ->join('lessons', 'videos.lesson_id', '=', 'lessons.id')
            ->where('video_watch_progress.student_id', $studentId)
            ->where('video_watch_progress.completion_percentage', '>=', self::VIDEO_COMPLETION_THRESHOLD)
            ->whereIn('lessons.subject_id', $subjectIds)
            ->where('videos.status', VideoStatus::Ready)
            ->groupBy('lessons.subject_id')
            ->selectRaw('lessons.subject_id as subject_id, COUNT(DISTINCT videos.id) as total')
            ->pluck('total', 'subject_id')
            ->map(fn ($count): int => (int) $count)
            ->all();
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<int, int>
     */
    private function assignmentTotalsBySubject(array $subjectIds): array
    {
        return Assignment::query()
            ->whereIn('subject_id', $subjectIds)
            ->where('status', ContentStatus::Active)
            ->groupBy('subject_id')
            ->selectRaw('subject_id, COUNT(*) as total')
            ->pluck('total', 'subject_id')
            ->map(fn ($count): int => (int) $count)
            ->all();
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<int, int>
     */
    private function completedAssignmentsBySubject(int $studentId, array $subjectIds): array
    {
        return AssignmentSubmission::query()
            ->join('assignments', 'assignment_submissions.assignment_id', '=', 'assignments.id')
            ->where('assignment_submissions.student_id', $studentId)
            ->whereIn('assignments.subject_id', $subjectIds)
            ->where('assignments.status', ContentStatus::Active)
            ->groupBy('assignments.subject_id')
            ->selectRaw('assignments.subject_id as subject_id, COUNT(DISTINCT assignments.id) as total')
            ->pluck('total', 'subject_id')
            ->map(fn ($count): int => (int) $count)
            ->all();
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<int, int>
     */
    private function quizTotalsBySubject(array $subjectIds): array
    {
        return Quiz::query()
            ->whereIn('subject_id', $subjectIds)
            ->where('status', ContentStatus::Active)
            ->groupBy('subject_id')
            ->selectRaw('subject_id, COUNT(*) as total')
            ->pluck('total', 'subject_id')
            ->map(fn ($count): int => (int) $count)
            ->all();
    }

    /**
     * @param  list<int>  $subjectIds
     * @return array<int, int>
     */
    private function completedQuizzesBySubject(int $studentId, array $subjectIds): array
    {
        return QuizAttempt::query()
            ->join('quizzes', 'quiz_attempts.quiz_id', '=', 'quizzes.id')
            ->where('quiz_attempts.student_id', $studentId)
            ->whereNotNull('quiz_attempts.submitted_at')
            ->whereIn('quizzes.subject_id', $subjectIds)
            ->where('quizzes.status', ContentStatus::Active)
            ->groupBy('quizzes.subject_id')
            ->selectRaw('quizzes.subject_id as subject_id, COUNT(DISTINCT quizzes.id) as total')
            ->pluck('total', 'subject_id')
            ->map(fn ($count): int => (int) $count)
            ->all();
    }
}
