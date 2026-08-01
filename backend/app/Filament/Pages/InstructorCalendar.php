<?php

namespace App\Filament\Pages;

use App\Filament\Concerns\InstructorOnlyPage;
use App\Models\User;
use App\Services\InstructorCalendarService;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Livewire\Attributes\Url;

class InstructorCalendar extends Page
{
    use InstructorOnlyPage;

    protected static ?string $navigationIcon = 'heroicon-o-calendar-days';

    protected static ?string $navigationGroup = 'التقويم والتواصل';

    protected static ?string $navigationLabel = 'التقويم';

    protected static ?string $title = 'التقويم';

    protected static ?int $navigationSort = 2;

    protected static string $view = 'filament.pages.instructor.calendar';

    #[Url]
    public ?string $selectedDate = null;

    public ?string $loadError = null;

    public function mount(): void
    {
        $this->selectedDate ??= now()->toDateString();
        $this->ensureSelectedDateInWeek();
    }

    public function loadCalendar(): void
    {
        $this->ensureSelectedDateInWeek();
    }

    public function getTitle(): string|Htmlable
    {
        return 'التقويم';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function selectDay(string $dateKey): void
    {
        $this->selectedDate = $dateKey;
    }

    /**
     * @return Collection<int, array<string, mixed>>
     */
    public function calendarDays(): Collection
    {
        $user = $this->authUser();

        if ($user === null) {
            return collect();
        }

        try {
            return app(InstructorCalendarService::class)->weekFor($user);
        } catch (\Throwable $exception) {
            report($exception);
            $this->loadError = 'تعذر تحميل التقويم.';

            return collect();
        }
    }

    /**
     * @return array<string, mixed>|null
     */
    public function selectedDay(): ?array
    {
        if ($this->selectedDate === null) {
            return null;
        }

        return $this->calendarDays()->firstWhere('date_key', $this->selectedDate);
    }

    protected function ensureSelectedDateInWeek(): void
    {
        $days = $this->calendarDays();

        if ($days->isEmpty()) {
            return;
        }

        if ($days->contains(fn (array $day): bool => $day['date_key'] === $this->selectedDate)) {
            return;
        }

        $today = $days->firstWhere('is_today', true);

        $this->selectedDate = $today['date_key'] ?? $days->first()['date_key'];
    }

    protected function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }
}
