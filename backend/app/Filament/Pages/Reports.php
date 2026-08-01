<?php

namespace App\Filament\Pages;

use App\Filament\Resources\ExpenseResource;
use App\Filament\Resources\SubjectStudentResource;
use App\Services\AccountingSummaryService;
use App\Services\ReportsService;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Carbon;
use Livewire\Attributes\Url;

class Reports extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-chart-bar';

    protected static ?string $navigationGroup = 'المحاسبة';

    protected static ?string $navigationLabel = 'التقارير';

    protected static ?string $title = 'التقارير';

    protected static ?int $navigationSort = 2;

    protected static string $view = 'filament.pages.reports';

    #[Url]
    public string $period = AccountingSummaryService::PERIOD_MONTH;

    #[Url]
    public ?string $customFrom = null;

    #[Url]
    public ?string $customTo = null;

    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    public function getTitle(): string|Htmlable
    {
        return 'التقارير';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function setPeriod(string $period): void
    {
        $this->period = $period;
    }

    /**
     * @return array<string, mixed>
     */
    public function reportData(): array
    {
        return app(ReportsService::class)->build(
            $this->period,
            $this->customFrom ? Carbon::parse($this->customFrom) : null,
            $this->customTo ? Carbon::parse($this->customTo) : null,
        );
    }

    public function formatMoney(float|int|string|null $amount): string
    {
        return AccountingSummaryService::formatMoney($amount);
    }

    public function accountingSummaryUrl(): string
    {
        return AccountingSummary::getUrl();
    }

    public function expensesIndexUrl(): string
    {
        return ExpenseResource::getUrl('index');
    }

    public function enrollmentsIndexUrl(): string
    {
        return SubjectStudentResource::getUrl('index');
    }
}
