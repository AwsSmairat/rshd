<?php

namespace App\Services;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\SubjectCategory;
use App\Filament\Resources\AssignmentResource;
use App\Filament\Resources\AssignmentSubmissionResource;
use App\Filament\Resources\SubjectResource;
use App\Models\Assignment;
use App\Models\AssignmentSubmission;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\LessonFile;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use App\Models\VideoWatchProgress;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class InstructorDashboardService
{
    public function __construct(
        protected InstructorCalendarService $calendarService,
    ) {}

    /**
     * @return array{
     *     stats: array<string, int>,
     *     pendingSubmissions: Collection<int, AssignmentSubmission>,
     *     recentActivities: Collection<int, array{title: string, subtitle: string, time: Carbon, icon: string}>,
     *     subjects: Collection<int, array{subject: Subject, students_count: int, lessons_count: int, announcements_count: int, icon: string}>,
     *     studentOverview: array{total: int, active: int, avg_progress: float, success_rate: float},
     *     coursePerformance: array{labels: list<string>, views: list<int>, submissions: list<int>},
     *     calendarDays: Collection<int, array{date: Carbon, label: string, is_today: bool, events: list<array{title: string, type: string}>}>,
     *     alerts: Collection<int, array{type: string, title: string, message: string, url: string|null}>
     * }
     */
    public function build(User $instructor): array
    {
        $subjectIds = $instructor->subjectsTeaching()->pluck('id');
        $stats = $this->stats($instructor, $subjectIds);

        return [
            'stats' => $stats,
            'pendingSubmissions' => $this->pendingSubmissions($subjectIds),
            'recentActivities' => $this->recentActivities($instructor, $subjectIds),
            'subjects' => $this->subjectsFor($instructor, 6),
            'studentOverview' => $this->studentOverview($subjectIds),
            'coursePerformance' => $this->coursePerformance($subjectIds),
            'calendarDays' => $this->calendarService->weekFor($instructor),
            'alerts' => $this->alerts($instructor, $subjectIds, $stats),
        ];
    }

    /**
     * @param  Collection<int, int>|Collection  $subjectIds
     * @return array<string, int>
     */
    protected function stats(User $instructor, $subjectIds): array
    {
        $subjectIds = collect($subjectIds);

        return [
            'subjects' => $subjectIds->count(),
            'lessons' => $subjectIds->isEmpty()
                ? 0
                : Lesson::query()->whereIn('subject_id', $subjectIds)->count(),
            'students' => $subjectIds->isEmpty()
                ? 0
                : (int) SubjectStudent::query()
                    ->whereIn('subject_id', $subjectIds)
                    ->where('access_status', AccessStatus::Active)
                    ->distinct()
                    ->count('student_id'),
            'pending_submissions' => $subjectIds->isEmpty()
                ? 0
                : AssignmentSubmission::query()
                    ->whereNull('grade')
                    ->whereHas('assignment', fn ($q) => $q->whereIn('subject_id', $subjectIds))
                    ->count(),
            'active_quizzes' => $subjectIds->isEmpty()
                ? 0
                : Quiz::query()
                    ->whereIn('subject_id', $subjectIds)
                    ->where('status', ContentStatus::Active)
                    ->count(),
        ];
    }

    /**
     * @param  Collection<int, int>|Collection  $subjectIds
     * @return array{total: int, active: int, avg_progress: float, success_rate: float}
     */
    protected function studentOverview($subjectIds): array
    {
        $subjectIds = collect($subjectIds);

        if ($subjectIds->isEmpty()) {
            return [
                'total' => 0,
                'active' => 0,
                'avg_progress' => 0,
                'success_rate' => 0,
            ];
        }

        $studentIds = SubjectStudent::query()
            ->whereIn('subject_id', $subjectIds)
            ->where('access_status', AccessStatus::Active)
            ->distinct()
            ->pluck('student_id');

        $total = $studentIds->count();
        $activeSince = now()->subDays(30);

        $activeStudentIds = collect()
            ->merge(
                VideoWatchProgress::query()
                    ->whereIn('student_id', $studentIds)
                    ->where('last_watched_at', '>=', $activeSince)
                    ->distinct()
                    ->pluck('student_id')
            )
            ->merge(
                AssignmentSubmission::query()
                    ->whereIn('student_id', $studentIds)
                    ->where('submitted_at', '>=', $activeSince)
                    ->distinct()
                    ->pluck('student_id')
            )
            ->merge(
                QuizAttempt::query()
                    ->whereIn('student_id', $studentIds)
                    ->where('submitted_at', '>=', $activeSince)
                    ->distinct()
                    ->pluck('student_id')
            )
            ->unique();

        $avgProgress = (float) VideoWatchProgress::query()
            ->whereIn('student_id', $studentIds)
            ->whereHas('video.lesson', fn ($q) => $q->whereIn('subject_id', $subjectIds))
            ->avg('completion_percentage');

        $gradedCount = Grade::query()
            ->whereIn('subject_id', $subjectIds)
            ->count();

        $passingCount = Grade::query()
            ->whereIn('subject_id', $subjectIds)
            ->where('grade', '>=', 60)
            ->count();

        if ($gradedCount === 0) {
            $quizAttempts = QuizAttempt::query()
                ->whereNotNull('submitted_at')
                ->whereNotNull('score')
                ->whereHas('quiz', fn ($q) => $q->whereIn('subject_id', $subjectIds))
                ->get(['score']);

            $gradedCount = $quizAttempts->count();
            $passingCount = $quizAttempts->where('score', '>=', 60)->count();
        }

        $successRate = $gradedCount > 0
            ? round(($passingCount / $gradedCount) * 100, 1)
            : 0;

        return [
            'total' => $total,
            'active' => $activeStudentIds->count(),
            'avg_progress' => round($avgProgress ?? 0, 1),
            'success_rate' => $successRate,
        ];
    }

    /**
     * @param  Collection<int, int>|Collection  $subjectIds
     * @return array{labels: list<string>, views: list<int>, submissions: list<int>, max_value: int}
     */
    protected function coursePerformance($subjectIds): array
    {
        $subjectIds = collect($subjectIds);
        $labels = [];
        $views = [];
        $submissions = [];

        for ($i = 6; $i >= 0; $i--) {
            $day = now()->subDays($i)->startOfDay();
            $end = $day->copy()->endOfDay();
            $labels[] = $day->locale('ar')->translatedFormat('D');

            if ($subjectIds->isEmpty()) {
                $views[] = 0;
                $submissions[] = 0;

                continue;
            }

            $views[] = VideoWatchProgress::query()
                ->whereBetween('last_watched_at', [$day, $end])
                ->whereHas('video.lesson', fn ($q) => $q->whereIn('subject_id', $subjectIds))
                ->count();

            $submissions[] = AssignmentSubmission::query()
                ->whereBetween('submitted_at', [$day, $end])
                ->whereHas('assignment', fn ($q) => $q->whereIn('subject_id', $subjectIds))
                ->count();
        }

        $maxValue = max(1, max(array_merge($views, $submissions)));

        return [
            'labels' => $labels,
            'views' => $views,
            'submissions' => $submissions,
            'max_value' => $maxValue,
        ];
    }

    /**
     * @param  Collection<int, int>|Collection  $subjectIds
     * @param  array<string, int>  $stats
     * @return Collection<int, array{type: string, title: string, message: string, url: string|null}>
     */
    protected function alerts(User $instructor, $subjectIds, array $stats): Collection
    {
        $subjectIds = collect($subjectIds);
        $alerts = collect();

        if (($stats['pending_submissions'] ?? 0) > 0) {
            $alerts->push([
                'type' => 'warning',
                'title' => 'تسليمات بانتظار التصحيح',
                'message' => 'لديك '.$stats['pending_submissions'].' تسليم يحتاج إلى تصحيح.',
                'url' => AssignmentSubmissionResource::getUrl('index', [
                    'tableFilters' => ['ungraded' => ['isActive' => true]],
                ]),
            ]);
        }

        if ($subjectIds->isNotEmpty()) {
            $dueSoon = Assignment::query()
                ->whereIn('subject_id', $subjectIds)
                ->where('status', ContentStatus::Active)
                ->whereBetween('due_date', [now(), now()->addDays(3)])
                ->count();

            if ($dueSoon > 0) {
                $alerts->push([
                    'type' => 'info',
                    'title' => 'مواعيد تسليم قريبة',
                    'message' => $dueSoon.' واجب/واجبات تنتهي خلال 3 أيام.',
                    'url' => AssignmentResource::getUrl('index'),
                ]);
            }
        }

        if ($subjectIds->isEmpty()) {
            $alerts->push([
                'type' => 'info',
                'title' => 'ابدأ بإضافة مادة',
                'message' => 'لم تُضف أي مواد بعد. أنشئ مادتك الأولى لبدء التعليم.',
                'url' => SubjectResource::getUrl('create'),
            ]);
        }

        return $alerts->take(4);
    }

    /**
     * @param  Collection<int, int>|Collection  $subjectIds
     * @return Collection<int, AssignmentSubmission>
     */
    protected function pendingSubmissions($subjectIds): Collection
    {
        $subjectIds = collect($subjectIds);

        if ($subjectIds->isEmpty()) {
            return collect();
        }

        return AssignmentSubmission::query()
            ->with(['student:id,name', 'assignment:id,title,subject_id', 'assignment.subject:id,title'])
            ->whereNull('grade')
            ->whereHas('assignment', fn ($q) => $q->whereIn('subject_id', $subjectIds))
            ->latest('submitted_at')
            ->limit(6)
            ->get();
    }

    /**
     * @param  Collection<int, int>|Collection  $subjectIds
     * @return Collection<int, array{title: string, subtitle: string, time: Carbon, icon: string}>
     */
    protected function recentActivities(User $instructor, $subjectIds): Collection
    {
        $subjectIds = collect($subjectIds);
        $items = collect();

        if ($subjectIds->isNotEmpty()) {
            Subject::query()
                ->where('instructor_id', $instructor->id)
                ->whereIn('id', $subjectIds)
                ->latest('created_at')
                ->limit(3)
                ->get()
                ->each(function (Subject $subject) use ($items): void {
                    $items->push([
                        'title' => 'أضفت مادة جديدة',
                        'subtitle' => '«'.$subject->title.'»',
                        'time' => $subject->created_at,
                        'icon' => 'book',
                    ]);
                });

            Lesson::query()
                ->with('subject:id,title')
                ->whereIn('subject_id', $subjectIds)
                ->latest('created_at')
                ->limit(3)
                ->get()
                ->each(function (Lesson $lesson) use ($items): void {
                    $items->push([
                        'title' => 'أضفت جزءاً جديداً',
                        'subtitle' => '«'.$lesson->title.'» — '.($lesson->subject?->title ?? 'مادة'),
                        'time' => $lesson->created_at,
                        'icon' => 'play',
                    ]);
                });

            Video::query()
                ->with(['lesson:id,title,subject_id', 'lesson.subject:id,title'])
                ->whereHas('lesson', fn ($q) => $q->whereIn('subject_id', $subjectIds))
                ->latest('created_at')
                ->limit(3)
                ->get()
                ->each(function (Video $video) use ($items): void {
                    $items->push([
                        'title' => 'رفعت فيديو',
                        'subtitle' => '«'.$video->title.'» — '.($video->lesson?->subject?->title ?? 'مادة'),
                        'time' => $video->created_at,
                        'icon' => 'video',
                    ]);
                });

            Assignment::query()
                ->with('subject:id,title')
                ->whereIn('subject_id', $subjectIds)
                ->latest('created_at')
                ->limit(3)
                ->get()
                ->each(function (Assignment $assignment) use ($items): void {
                    $items->push([
                        'title' => 'أنشأت واجباً',
                        'subtitle' => '«'.$assignment->title.'» — '.($assignment->subject?->title ?? 'مادة'),
                        'time' => $assignment->created_at,
                        'icon' => 'assignment',
                    ]);
                });

            Quiz::query()
                ->with('subject:id,title')
                ->whereIn('subject_id', $subjectIds)
                ->latest('created_at')
                ->limit(3)
                ->get()
                ->each(function (Quiz $quiz) use ($items): void {
                    $items->push([
                        'title' => 'أنشأت اختباراً',
                        'subtitle' => '«'.$quiz->title.'» — '.($quiz->subject?->title ?? 'مادة'),
                        'time' => $quiz->created_at,
                        'icon' => 'quiz',
                    ]);
                });

            AssignmentSubmission::query()
                ->with(['student:id,name', 'assignment:id,title,subject_id'])
                ->whereHas('assignment', fn ($q) => $q->whereIn('subject_id', $subjectIds))
                ->latest('submitted_at')
                ->limit(5)
                ->get()
                ->each(function (AssignmentSubmission $submission) use ($items): void {
                    if ($submission->submitted_at === null) {
                        return;
                    }

                    $items->push([
                        'title' => ($submission->student?->name ?? 'طالب').' سلّم واجب',
                        'subtitle' => $submission->assignment?->title ?? 'واجب',
                        'time' => $submission->submitted_at,
                        'icon' => 'clipboard',
                    ]);
                });

            QuizAttempt::query()
                ->with(['student:id,name', 'quiz:id,title,subject_id'])
                ->whereNotNull('submitted_at')
                ->whereHas('quiz', fn ($q) => $q->whereIn('subject_id', $subjectIds))
                ->latest('submitted_at')
                ->limit(5)
                ->get()
                ->each(function (QuizAttempt $attempt) use ($items): void {
                    $items->push([
                        'title' => ($attempt->student?->name ?? 'طالب').' أنهى اختبار',
                        'subtitle' => $attempt->quiz?->title ?? 'اختبار',
                        'time' => $attempt->submitted_at,
                        'icon' => 'quiz',
                    ]);
                });

            VideoWatchProgress::query()
                ->with(['student:id,name', 'video:id,title,lesson_id', 'video.lesson:id,subject_id,title'])
                ->whereHas('video.lesson', fn ($q) => $q->whereIn('subject_id', $subjectIds))
                ->whereNotNull('last_watched_at')
                ->latest('last_watched_at')
                ->limit(5)
                ->get()
                ->each(function (VideoWatchProgress $progress) use ($items): void {
                    $items->push([
                        'title' => ($progress->student?->name ?? 'طالب').' شاهد محاضرة',
                        'subtitle' => $progress->video?->title ?? 'محاضرة',
                        'time' => $progress->last_watched_at,
                        'icon' => 'video',
                    ]);
                });

            LessonFile::query()
                ->with(['lesson:id,title,subject_id'])
                ->whereHas('lesson', fn ($q) => $q->whereIn('subject_id', $subjectIds))
                ->latest('created_at')
                ->limit(5)
                ->get()
                ->each(function (LessonFile $file) use ($items): void {
                    $items->push([
                        'title' => 'تم رفع ملف جديد',
                        'subtitle' => $file->title.' — '.($file->lesson?->title ?? 'درس'),
                        'time' => $file->created_at,
                        'icon' => 'file',
                    ]);
                });
        }

        return $items
            ->sortByDesc(fn (array $item) => $item['time']?->timestamp ?? 0)
            ->take(5)
            ->values();
    }

    /**
     * @return Collection<int, array{subject: Subject, students_count: int, lessons_count: int, announcements_count: int, icon: string}>
     */
    public function subjectsFor(User $instructor, ?int $limit = null): Collection
    {
        $query = $instructor->subjectsTeaching()
            ->withCount([
                'lessons',
                'enrollments as students_count' => fn ($q) => $q->where('access_status', AccessStatus::Active),
            ])
            ->latest();

        if ($limit !== null) {
            $query->limit($limit);
        }

        return $query
            ->get()
            ->map(fn (Subject $subject) => [
                'subject' => $subject,
                'students_count' => (int) $subject->students_count,
                'lessons_count' => (int) $subject->lessons_count,
                'icon' => $this->categoryIcon($subject->category),
            ]);
    }

    /**
     * @return Collection<int, array{subject: Subject, students_count: int, lessons_count: int, announcements_count: int, icon: string}>
     */
    protected function subjects(User $instructor): Collection
    {
        return $this->subjectsFor($instructor, 6);
    }

    protected function categoryIcon(?SubjectCategory $category): string
    {
        return match ($category) {
            SubjectCategory::Medicine => 'medicine',
            SubjectCategory::It => 'code',
            SubjectCategory::Engineering => 'engineering',
            default => 'book',
        };
    }
}
