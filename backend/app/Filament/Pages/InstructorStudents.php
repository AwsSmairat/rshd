<?php

namespace App\Filament\Pages;

use App\Enums\AccessStatus;
use App\Enums\UserRole;
use App\Filament\Concerns\InstructorOnlyPage;
use App\Models\User;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;

class InstructorStudents extends Page
{
    use InstructorOnlyPage;

    protected static ?string $navigationIcon = 'heroicon-o-user-group';

    protected static ?string $navigationGroup = 'الإدارة والتحليلات';

    protected static ?string $navigationLabel = 'الطلاب';

    protected static ?string $title = 'طلابي';

    protected static ?int $navigationSort = 1;

    protected static string $view = 'filament.pages.instructor.students';

    public ?string $loadError = null;

    /** @var Collection<int, array{student: User, subject_titles: list<string>}> */
    public Collection $studentRows;

    public function mount(): void
    {
        $this->studentRows = collect();
        $this->loadStudents();
    }

    public function getTitle(): string|Htmlable
    {
        return 'طلابي';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function loadStudents(): void
    {
        $user = $this->authUser();

        if ($user === null) {
            $this->studentRows = collect();

            return;
        }

        try {
            $subjectIds = $user->subjectsTeaching()->pluck('id');

            if ($subjectIds->isEmpty()) {
                $this->studentRows = collect();

                return;
            }

            $students = User::query()
                ->where('role', UserRole::Student)
                ->whereHas(
                    'enrolledSubjects',
                    fn ($query) => $query
                        ->whereIn('subjects.id', $subjectIds)
                        ->where('subject_students.access_status', AccessStatus::Active->value),
                )
                ->with([
                    'enrolledSubjects' => fn ($query) => $query
                        ->whereIn('subjects.id', $subjectIds)
                        ->where('subject_students.access_status', AccessStatus::Active->value)
                        ->select('subjects.id', 'subjects.title'),
                ])
                ->orderBy('name')
                ->get();

            $this->studentRows = $students->map(function (User $student): array {
                return [
                    'student' => $student,
                    'subject_titles' => $student->enrolledSubjects
                        ->pluck('title')
                        ->values()
                        ->all(),
                ];
            });
        } catch (\Throwable $exception) {
            report($exception);
            $this->loadError = 'تعذر تحميل قائمة الطلاب.';
            $this->studentRows = collect();
        }
    }

    public function enrollmentCount(): int
    {
        return $this->studentRows->sum(
            fn (array $row): int => count($row['subject_titles'])
        );
    }

    protected function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }
}
