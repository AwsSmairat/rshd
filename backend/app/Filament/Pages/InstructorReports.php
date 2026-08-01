<?php

namespace App\Filament\Pages;

use App\Filament\Concerns\InstructorOnlyPage;
use App\Filament\Resources\AssignmentResource;
use App\Filament\Resources\AssignmentSubmissionResource;
use App\Filament\Resources\LessonResource;
use App\Filament\Resources\SubjectResource;
use App\Models\User;
use App\Services\InstructorDashboardService;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Facades\Auth;

class InstructorReports extends Page
{
    use InstructorOnlyPage;

    protected static ?string $navigationIcon = 'heroicon-o-chart-pie';

    protected static ?string $navigationGroup = 'الإدارة والتحليلات';

    protected static ?string $navigationLabel = 'التقارير والإحصائيات';

    protected static ?string $title = 'التقارير والإحصائيات';

    protected static ?int $navigationSort = 3;

    protected static string $view = 'filament.pages.instructor.reports';

    public ?string $loadError = null;

    /** @var array<string, mixed> */
    public array $reportPayload = [];

    public function mount(): void
    {
        $this->loadReport();
    }

    public function getTitle(): string|Htmlable
    {
        return 'التقارير والإحصائيات';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function loadReport(): void
    {
        $user = $this->authUser();

        if ($user === null) {
            $this->reportPayload = [];

            return;
        }

        try {
            $data = app(InstructorDashboardService::class)->build($user);

            $this->reportPayload = [
                'stats' => $data['stats'],
                'studentOverview' => $data['studentOverview'],
                'coursePerformance' => $data['coursePerformance'],
            ];
        } catch (\Throwable $exception) {
            report($exception);
            $this->loadError = 'تعذر تحميل التقارير.';
            $this->reportPayload = [];
        }
    }

    public function subjectsUrl(): string
    {
        return SubjectResource::getUrl('index');
    }

    public function studentsUrl(): string
    {
        return InstructorStudents::getUrl();
    }

    public function lessonsUrl(): string
    {
        return LessonResource::getUrl('index');
    }

    public function submissionsUrl(): string
    {
        return AssignmentSubmissionResource::getUrl('index');
    }

    public function pendingSubmissionsUrl(): string
    {
        return AssignmentSubmissionResource::getUrl('index', [
            'tableFilters' => [
                'ungraded' => ['isActive' => true],
            ],
        ]);
    }

    public function assignmentsUrl(): string
    {
        return AssignmentResource::getUrl('index');
    }

    /**
     * @return array<int, array{key: string, label: string, url: string}>
     */
    public function statCards(): array
    {
        return [
            ['key' => 'subjects', 'label' => 'المواد', 'url' => $this->subjectsUrl()],
            ['key' => 'students', 'label' => 'الطلاب', 'url' => $this->studentsUrl()],
            ['key' => 'lessons', 'label' => 'الأجزاء', 'url' => $this->lessonsUrl()],
            ['key' => 'pending_submissions', 'label' => 'بانتظار التصحيح', 'url' => $this->pendingSubmissionsUrl()],
        ];
    }

    protected function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }
}
