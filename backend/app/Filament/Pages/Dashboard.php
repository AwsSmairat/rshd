<?php

namespace App\Filament\Pages;

use App\Filament\Pages\InstructorCalendar;
use App\Filament\Pages\InstructorCourses;
use App\Filament\Pages\InstructorProfile;
use App\Filament\Pages\InstructorReports;
use App\Filament\Pages\InstructorStudents;
use App\Filament\Resources\AnnouncementResource;
use App\Filament\Resources\AssignmentResource;
use App\Filament\Resources\AssignmentSubmissionResource;
use App\Filament\Resources\ExpenseResource;
use App\Filament\Resources\InstructorResource;
use App\Filament\Resources\LessonFileResource;
use App\Filament\Resources\LessonResource;
use App\Filament\Resources\NotificationResource;
use App\Filament\Resources\QuizResource;
use App\Filament\Resources\StudentResource;
use App\Filament\Resources\SubjectResource;
use App\Filament\Resources\SubjectStudentResource;
use App\Filament\Resources\VideoResource;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Services\AdminDashboardService;
use App\Services\EnrollmentService;
use App\Services\InstructorDashboardService;
use App\Services\PlatformSettingsService;
use Filament\Facades\Filament;
use Filament\Notifications\Notification;
use Filament\Pages\Dashboard as BaseDashboard;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\Facades\Auth;

class Dashboard extends BaseDashboard
{
    protected static ?string $navigationIcon = 'heroicon-o-home';

    protected static ?string $navigationGroup = 'الرئيسية';

    protected static ?string $navigationLabel = 'لوحة التحكم';

    protected static ?int $navigationSort = -2;

    protected static string $view = 'filament.pages.dashboard';

    public function getTitle(): string|Htmlable
    {
        return 'لوحة التحكم';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    /**
     * @return array<class-string>
     */
    public function getWidgets(): array
    {
        return [];
    }

    public function getColumns(): int|string|array
    {
        return 1;
    }

    public function isInstructor(): bool
    {
        return $this->authUser()?->isInstructor() ?? false;
    }

    public function isAdmin(): bool
    {
        return $this->authUser()?->isAdmin() ?? false;
    }

    public function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }

    public ?string $instructorDashboardError = null;

    /**
     * @return array{
     *     stats: array<string, int>,
     *     pendingSubmissions: \Illuminate\Support\Collection,
     *     recentActivities: \Illuminate\Support\Collection,
     *     subjects: \Illuminate\Support\Collection,
     *     studentOverview: array<string, int|float>,
     *     coursePerformance: array<string, mixed>,
     *     calendarDays: \Illuminate\Support\Collection,
     *     alerts: \Illuminate\Support\Collection
     * }|null
     */
    public function instructorData(): ?array
    {
        $user = $this->authUser();

        if ($user === null || ! $user->isInstructor()) {
            return null;
        }

        try {
            return app(InstructorDashboardService::class)->build($user);
        } catch (\Throwable $exception) {
            report($exception);
            $this->instructorDashboardError = 'تعذر تحميل بيانات لوحة التحكم. حاول تحديث الصفحة.';

            return null;
        }
    }

    /**
     * @return array<string, mixed>|null
     */
    public function adminData(): ?array
    {
        if (! $this->isAdmin()) {
            return null;
        }

        return app(AdminDashboardService::class)->build();
    }

    public function instructorInitials(): string
    {
        return $this->userInitials('م');
    }

    public function adminInitials(): string
    {
        return $this->userInitials('أ');
    }

    protected function userInitials(string $fallback): string
    {
        $name = trim((string) $this->authUser()?->name);

        if ($name === '') {
            return $fallback;
        }

        $parts = preg_split('/\s+/u', $name) ?: [];
        $first = mb_substr($parts[0] ?? '', 0, 1);
        $second = mb_substr($parts[1] ?? '', 0, 1);

        return mb_strtoupper($first.$second) ?: $fallback;
    }

    public function logoutUrl(): string
    {
        return Filament::getLogoutUrl();
    }

    public function formatMoney(float|int|string|null $amount): string
    {
        $symbol = (string) (app(PlatformSettingsService::class)->get('currency_symbol', 'د.أ', 'platform') ?: 'د.أ');

        return number_format((float) ($amount ?? 0), 2).' '.$symbol;
    }

    public function activateEnrollment(int $enrollmentId): void
    {
        if (! $this->isAdmin()) {
            return;
        }

        $record = SubjectStudent::query()->with(['student', 'subject'])->find($enrollmentId);
        $admin = $this->authUser();

        if ($record === null || $record->student === null || $record->subject === null || $admin === null) {
            Notification::make()->title('تعذر التفعيل')->danger()->send();

            return;
        }

        app(EnrollmentService::class)->activateStudent(
            $record->student,
            $record->subject,
            $admin,
        );

        Notification::make()->title('تم تفعيل المادة للطالب')->success()->send();
    }

    public function rejectEnrollment(int $enrollmentId): void
    {
        if (! $this->isAdmin()) {
            return;
        }

        $record = SubjectStudent::query()->with(['student', 'subject'])->find($enrollmentId);

        if ($record === null || $record->student === null || $record->subject === null) {
            Notification::make()->title('تعذر الرفض')->danger()->send();

            return;
        }

        app(EnrollmentService::class)->revokeAccess($record->student, $record->subject);

        Notification::make()->title('تم رفض طلب التفعيل')->success()->send();
    }

    /**
     * @return array<int, array{label: string, icon: string, url: string|null, enabled: bool}>
     */
    public function adminQuickActions(): array
    {
        $settings = app(PlatformSettingsService::class);

        return [
            [
                'label' => 'تفعيل مادة لطالب',
                'icon' => 'clipboard',
                'url' => SubjectStudentResource::getUrl('create'),
                'enabled' => true,
                'disabledReason' => null,
            ],
            [
                'label' => 'إضافة مصروف',
                'icon' => 'file',
                'url' => ExpenseResource::getUrl('create'),
                'enabled' => true,
                'disabledReason' => null,
            ],
            [
                'label' => 'إرسال إشعار',
                'icon' => 'megaphone',
                'url' => NotificationResource::getUrl('create'),
                'enabled' => $settings->enabled('in_app_notifications_enabled', 'notifications'),
                'disabledReason' => 'الإشارات داخل التطبيق معطّلة في إعدادات المنصة',
            ],
            [
                'label' => 'إدارة الطلاب',
                'icon' => 'users',
                'url' => StudentResource::getUrl('index'),
                'enabled' => true,
                'disabledReason' => null,
            ],
            [
                'label' => 'إدارة المدرسين',
                'icon' => 'play',
                'url' => InstructorResource::getUrl('index'),
                'enabled' => true,
                'disabledReason' => null,
            ],
            [
                'label' => 'عرض التقارير',
                'icon' => 'quiz',
                'url' => Reports::getUrl(),
                'enabled' => true,
                'disabledReason' => null,
            ],
        ];
    }

    /**
     * @return array<int, array{label: string, icon: string, url: string|null, enabled: bool}>
     */
    public function quickActions(): array
    {
        return [
            [
                'label' => 'إضافة مادة',
                'icon' => 'book',
                'url' => SubjectResource::getUrl('create'),
                'enabled' => true,
            ],
            [
                'label' => 'إضافة درس',
                'icon' => 'play',
                'url' => LessonResource::getUrl('create'),
                'enabled' => true,
            ],
            [
                'label' => 'رفع فيديو',
                'icon' => 'video',
                'url' => VideoResource::getUrl('create'),
                'enabled' => true,
            ],
            [
                'label' => 'رفع ملف PDF',
                'icon' => 'file',
                'url' => LessonFileResource::getUrl('create'),
                'enabled' => true,
            ],
            [
                'label' => 'إنشاء واجب',
                'icon' => 'assignment',
                'url' => AssignmentResource::getUrl('create'),
                'enabled' => true,
            ],
            [
                'label' => 'إنشاء اختبار',
                'icon' => 'quiz',
                'url' => QuizResource::getUrl('create'),
                'enabled' => true,
            ],
            [
                'label' => 'إرسال إعلان',
                'icon' => 'megaphone',
                'url' => AnnouncementResource::getUrl('create'),
                'enabled' => AnnouncementResource::canCreate(),
            ],
        ];
    }

    public function instructorProfileUrl(): string
    {
        return InstructorProfile::getUrl();
    }

    public function instructorCoursesUrl(): string
    {
        return InstructorCourses::getUrl();
    }

    public function instructorStudentsUrl(): string
    {
        return InstructorStudents::getUrl();
    }

    public function instructorReportsUrl(): string
    {
        return InstructorReports::getUrl();
    }

    public function instructorCalendarUrl(?string $dateKey = null): string
    {
        $url = InstructorCalendar::getUrl();

        if ($dateKey === null || $dateKey === '') {
            return $url;
        }

        return $url.'?selectedDate='.urlencode($dateKey);
    }

    public function announcementsIndexUrl(): string
    {
        return AnnouncementResource::getUrl('index');
    }

    public function quizzesIndexUrl(): string
    {
        return QuizResource::getUrl('index');
    }

    public function lessonsIndexUrl(): string
    {
        return LessonResource::getUrl('index');
    }

    public function pendingSubmissionsUrl(): string
    {
        return AssignmentSubmissionResource::getUrl('index', [
            'tableFilters' => [
                'ungraded' => ['isActive' => true],
            ],
        ]);
    }

    /**
     * @return array<int, array{key: string, label: string, unit: string, icon: string, url: string}>
     */
    public function instructorStatCards(): array
    {
        return [
            ['key' => 'subjects', 'label' => 'المواد', 'unit' => 'مادة', 'icon' => 'book', 'url' => $this->subjectsIndexUrl()],
            ['key' => 'lessons', 'label' => 'الدروس', 'unit' => 'درس', 'icon' => 'play', 'url' => $this->lessonsIndexUrl()],
            ['key' => 'students', 'label' => 'الطلاب', 'unit' => 'طالب', 'icon' => 'users', 'url' => $this->instructorStudentsUrl()],
            ['key' => 'active_quizzes', 'label' => 'اختبارات نشطة', 'unit' => 'اختبار', 'icon' => 'quiz', 'url' => $this->quizzesIndexUrl()],
            ['key' => 'pending_submissions', 'label' => 'بانتظار التصحيح', 'unit' => 'تسليم', 'icon' => 'clipboard', 'url' => $this->pendingSubmissionsUrl()],
            ['key' => 'announcements', 'label' => 'إعلانات منشورة', 'unit' => 'إعلان', 'icon' => 'megaphone', 'url' => $this->announcementsIndexUrl()],
        ];
    }

    public function enrollmentsIndexUrl(): string
    {
        return SubjectStudentResource::getUrl('index');
    }

    public function accountingSummaryUrl(): string
    {
        return AccountingSummary::getUrl();
    }

    public function submissionsIndexUrl(): string
    {
        return AssignmentSubmissionResource::getUrl('index');
    }

    public function submissionEditUrl(int|string $recordId): string
    {
        return AssignmentSubmissionResource::getUrl('edit', ['record' => $recordId]);
    }

    public function subjectsIndexUrl(): string
    {
        return SubjectResource::getUrl('index');
    }

    public function subjectLessonsUrl(int|string $subjectId): string
    {
        return $this->resourceIndexWithSubjectFilter(LessonResource::class, $subjectId);
    }

    public function subjectVideosUrl(int|string $subjectId): string
    {
        return $this->resourceIndexWithSubjectFilter(VideoResource::class, $subjectId);
    }

    public function subjectFilesUrl(int|string $subjectId): string
    {
        return $this->resourceIndexWithSubjectFilter(LessonFileResource::class, $subjectId);
    }

    public function subjectAssignmentsUrl(int|string $subjectId): string
    {
        return $this->resourceIndexWithSubjectFilter(AssignmentResource::class, $subjectId);
    }

    public function subjectQuizzesUrl(int|string $subjectId): string
    {
        return $this->resourceIndexWithSubjectFilter(QuizResource::class, $subjectId);
    }

    public function subjectEditUrl(int|string $subjectId): string
    {
        return SubjectResource::getUrl('edit', ['record' => $subjectId]);
    }

    public function instructorNotificationsUrl(): string
    {
        $pending = (int) ($this->instructorData()['stats']['pending_submissions'] ?? 0);

        if ($pending > 0) {
            return AssignmentSubmissionResource::getUrl('index', [
                'tableFilters' => [
                    'ungraded' => ['isActive' => true],
                ],
            ]);
        }

        return AssignmentSubmissionResource::getUrl('index');
    }

    public function instructorPendingCount(): int
    {
        return (int) ($this->instructorData()['stats']['pending_submissions'] ?? 0);
    }

    /**
     * @param  class-string  $resourceClass
     */
    protected function resourceIndexWithSubjectFilter(string $resourceClass, int|string $subjectId): string
    {
        return $resourceClass::getUrl('index', [
            'tableFilters' => [
                'subject_id' => ['value' => (string) $subjectId],
            ],
        ]);
    }
}
