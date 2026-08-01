<?php

namespace App\Filament\Pages;

use App\Filament\Concerns\InstructorOnlyPage;
use App\Filament\Concerns\MapsInstructorSubjectUrls;
use App\Filament\Resources\SubjectResource;
use App\Models\User;
use App\Services\InstructorDashboardService;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;

class InstructorCourses extends Page
{
    use InstructorOnlyPage;
    use MapsInstructorSubjectUrls;

    protected static ?string $navigationIcon = 'heroicon-o-academic-cap';

    protected static ?string $navigationGroup = 'الإدارة والتحليلات';

    protected static ?string $navigationLabel = 'الدورات';

    protected static ?string $title = 'الدورات النشطة';

    protected static ?int $navigationSort = 2;

    protected static string $view = 'filament.pages.instructor.courses';

    public ?string $loadError = null;

    /** @var Collection<int, array{subject: \App\Models\Subject, students_count: int, lessons_count: int, announcements_count: int, icon: string}> */
    public Collection $courses;

    public function mount(): void
    {
        $this->courses = collect();
        $this->loadCourses();
    }

    public function getTitle(): string|Htmlable
    {
        return 'الدورات النشطة';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function loadCourses(): void
    {
        $user = $this->authUser();

        if ($user === null) {
            $this->courses = collect();

            return;
        }

        try {
            $this->courses = app(InstructorDashboardService::class)->subjectsFor($user);
        } catch (\Throwable $exception) {
            report($exception);
            $this->loadError = 'تعذر تحميل الدورات.';
            $this->courses = collect();
        }
    }

    public function subjectCreateUrl(): string
    {
        return SubjectResource::getUrl('create');
    }

    protected function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }
}
