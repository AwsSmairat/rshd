<?php

namespace App\Filament\Pages;

use App\Enums\AccessStatus;
use App\Filament\Concerns\InstructorOnlyPage;
use App\Filament\Concerns\MapsInstructorSubjectUrls;
use App\Filament\Resources\VideoResource;
use App\Models\User;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class InstructorCertificates extends Page
{
    use InstructorOnlyPage;
    use MapsInstructorSubjectUrls;

    protected static ?string $navigationIcon = 'heroicon-o-document-check';

    protected static ?string $navigationGroup = 'الإدارة والتحليلات';

    protected static ?string $navigationLabel = 'الشهادات';

    protected static ?string $title = 'الشهادات';

    protected static ?int $navigationSort = 5;

    protected static string $view = 'filament.pages.instructor.certificates';

    public ?string $loadError = null;

    /** @var Collection<int, array{student_id: int, student_name: string, student_email: string|null, subject_id: int, subject_title: string, avg_progress: float, eligible: bool}> */
    public Collection $candidates;

    public int $videoCount = 0;

    public function mount(): void
    {
        $this->candidates = collect();
        $this->loadCandidates();
    }

    public function getTitle(): string|Htmlable
    {
        return 'الشهادات';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function loadCandidates(): void
    {
        $user = $this->authUser();

        if ($user === null) {
            $this->candidates = collect();

            return;
        }

        try {
            $subjectIds = $user->subjectsTeaching()->pluck('id');

            if ($subjectIds->isEmpty()) {
                $this->candidates = collect();

                return;
            }

            $this->videoCount = (int) DB::table('videos as v')
                ->join('lessons as l', 'l.id', '=', 'v.lesson_id')
                ->whereIn('l.subject_id', $subjectIds)
                ->count();

            $rows = DB::table('subject_students as ss')
                ->join('users as u', 'u.id', '=', 'ss.student_id')
                ->join('subjects as s', 's.id', '=', 'ss.subject_id')
                ->leftJoin('lessons as l', 'l.subject_id', '=', 's.id')
                ->leftJoin('videos as v', 'v.lesson_id', '=', 'l.id')
                ->leftJoin('video_watch_progress as vwp', function ($join): void {
                    $join->on('vwp.video_id', '=', 'v.id')
                        ->on('vwp.student_id', '=', 'ss.student_id');
                })
                ->whereIn('ss.subject_id', $subjectIds)
                ->where('ss.access_status', AccessStatus::Active->value)
                ->groupBy('ss.student_id', 'ss.subject_id', 'u.id', 'u.name', 'u.email', 's.id', 's.title')
                ->select([
                    'u.id as student_id',
                    'u.name as student_name',
                    'u.email as student_email',
                    's.id as subject_id',
                    's.title as subject_title',
                    DB::raw('COALESCE(AVG(vwp.completion_percentage), 0) as avg_progress'),
                ])
                ->orderByDesc('avg_progress')
                ->get();

            $studentIds = $rows->pluck('student_id')->unique();
            $students = User::query()->whereIn('id', $studentIds)->get()->keyBy('id');

            $this->candidates = $rows->map(function ($row) use ($students): array {
                $progress = round((float) $row->avg_progress, 1);
                $student = $students->get($row->student_id);

                return [
                    'student_id' => (int) $row->student_id,
                    'student_name' => $student?->name ?? (string) $row->student_name,
                    'student_email' => $student?->email ?? $row->student_email,
                    'subject_id' => (int) $row->subject_id,
                    'subject_title' => (string) $row->subject_title,
                    'avg_progress' => $progress,
                    'eligible' => $progress >= 80,
                ];
            });
        } catch (\Throwable $exception) {
            report($exception);
            $this->loadError = 'تعذر تحميل بيانات الشهادات.';
            $this->candidates = collect();
        }
    }

    public function studentsUrl(): string
    {
        return InstructorStudents::getUrl();
    }

    public function attendanceUrl(): string
    {
        return InstructorAttendance::getUrl();
    }

    public function videosUrl(): string
    {
        return VideoResource::getUrl('index');
    }

    public function eligibleCount(): int
    {
        return $this->candidates->where('eligible', true)->count();
    }

    public function hasWatchData(): bool
    {
        return $this->candidates->contains(fn (array $row): bool => $row['avg_progress'] > 0);
    }

    protected function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }
}
