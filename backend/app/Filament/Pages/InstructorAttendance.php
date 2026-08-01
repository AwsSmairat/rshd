<?php

namespace App\Filament\Pages;

use App\Enums\AccessStatus;
use App\Filament\Concerns\InstructorOnlyPage;
use App\Filament\Concerns\MapsInstructorSubjectUrls;
use App\Filament\Resources\VideoResource;
use App\Models\User;
use App\Models\VideoWatchProgress;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class InstructorAttendance extends Page
{
    use InstructorOnlyPage;
    use MapsInstructorSubjectUrls;

    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-check';

    protected static ?string $navigationGroup = 'الإدارة والتحليلات';

    protected static ?string $navigationLabel = 'الحضور';

    protected static ?string $title = 'الحضور';

    protected static ?int $navigationSort = 4;

    protected static string $view = 'filament.pages.instructor.attendance';

    public ?string $loadError = null;

    /** @var Collection<int, VideoWatchProgress> */
    public Collection $activities;

    public int $videoCount = 0;

    public int $studentCount = 0;

    public function mount(): void
    {
        $this->activities = collect();
        $this->loadActivities();
    }

    public function getTitle(): string|Htmlable
    {
        return 'الحضور';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function loadActivities(): void
    {
        $user = $this->authUser();

        if ($user === null) {
            $this->activities = collect();

            return;
        }

        try {
            $subjectIds = $user->subjectsTeaching()->pluck('id');

            if ($subjectIds->isEmpty()) {
                $this->activities = collect();
                $this->videoCount = 0;
                $this->studentCount = 0;

                return;
            }

            $this->videoCount = (int) DB::table('videos as v')
                ->join('lessons as l', 'l.id', '=', 'v.lesson_id')
                ->whereIn('l.subject_id', $subjectIds)
                ->count();

            $this->studentCount = (int) DB::table('subject_students')
                ->whereIn('subject_id', $subjectIds)
                ->where('access_status', AccessStatus::Active->value)
                ->distinct('student_id')
                ->count('student_id');

            $this->activities = VideoWatchProgress::query()
                ->with([
                    'student:id,name,email',
                    'video:id,title,lesson_id',
                    'video.lesson:id,title,subject_id',
                    'video.lesson.subject:id,title',
                ])
                ->whereHas('video.lesson', fn ($query) => $query->whereIn('subject_id', $subjectIds))
                ->whereNotNull('last_watched_at')
                ->latest('last_watched_at')
                ->limit(40)
                ->get();
        } catch (\Throwable $exception) {
            report($exception);
            $this->loadError = 'تعذر تحميل سجل النشاط.';
            $this->activities = collect();
        }
    }

    public function studentsUrl(): string
    {
        return InstructorStudents::getUrl();
    }

    public function videosUrl(): string
    {
        return VideoResource::getUrl('index');
    }

    public function certificatesUrl(): string
    {
        return InstructorCertificates::getUrl();
    }

    public function videoEditUrl(int|string $videoId): string
    {
        return VideoResource::getUrl('edit', ['record' => $videoId]);
    }

    public function hasVideosButNoActivity(): bool
    {
        return $this->videoCount > 0 && $this->activities->isEmpty();
    }

    public function hasStudentsButNoActivity(): bool
    {
        return $this->studentCount > 0 && $this->activities->isEmpty();
    }

    protected function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }
}
