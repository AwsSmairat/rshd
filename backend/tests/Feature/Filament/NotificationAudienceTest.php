<?php

namespace Tests\Feature\Filament;

use App\Enums\AccessStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\NotificationResource;
use App\Filament\Resources\NotificationResource\Pages\CreateNotification;
use App\Models\AppNotification;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Services\PlatformSettingsService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

class NotificationAudienceTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        app(PlatformSettingsService::class)->set('email_notifications_enabled', false, 'notifications');

        $admin = User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
            'password_set_at' => now(),
        ]);
        $admin->assignRole(UserRole::Admin->value);
        $this->actingAs($admin);
    }

    public function test_all_students_reaches_active_students_only(): void
    {
        $active = [$this->createStudent(), $this->createStudent()];
        $this->createStudent(['status' => UserStatus::Blocked]);

        Livewire::test(CreateNotification::class)
            ->fillForm([
                'audience' => NotificationResource::AUDIENCE_ALL_STUDENTS,
                'title' => 'تحديث المنصة',
                'body' => 'تمت إضافة ميزات جديدة.',
                'type' => 'custom',
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertEqualsCanonicalizing(
            array_map(fn (User $user): int => $user->id, $active),
            AppNotification::query()->pluck('user_id')->all(),
        );
    }

    public function test_subject_audience_reaches_its_activated_students_with_the_tap_target(): void
    {
        $subject = $this->createSubject();
        $lesson = $this->createLesson($subject);
        $enrolled = $this->createStudent();
        $pending = $this->createStudent();
        $this->createStudent();

        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $enrolled->id,
            'payment_status' => PaymentStatus::Paid,
            'access_status' => AccessStatus::Active,
            'activated_at' => now(),
        ]);
        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $pending->id,
            'payment_status' => PaymentStatus::Unpaid,
            'access_status' => AccessStatus::Pending,
        ]);

        Livewire::test(CreateNotification::class)
            ->fillForm([
                'audience' => NotificationResource::AUDIENCE_SUBJECT,
                'audience_subject_id' => $subject->id,
                'title' => 'محاضرة جديدة',
                'body' => 'تمت إضافة محاضرة.',
                'type' => 'lesson_published',
                'target_subject_id' => $subject->id,
                'target_lesson_id' => $lesson->id,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $notification = AppNotification::query()->sole();
        $this->assertSame($enrolled->id, $notification->user_id);
        $this->assertSame(['subject_id' => $subject->id, 'lesson_id' => $lesson->id], $notification->data);
    }

    public function test_selected_students_and_a_single_user(): void
    {
        $picked = [$this->createStudent(), $this->createStudent()];
        $this->createStudent();

        Livewire::test(CreateNotification::class)
            ->fillForm([
                'audience' => NotificationResource::AUDIENCE_STUDENTS,
                'student_ids' => array_map(fn (User $user): int => $user->id, $picked),
                'title' => 'تذكير',
                'body' => 'لا تنسوا الواجب.',
                'type' => 'custom',
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertSame(2, AppNotification::query()->count());

        $single = $this->createStudent();
        Livewire::test(CreateNotification::class)
            ->fillForm([
                'audience' => NotificationResource::AUDIENCE_USER,
                'user_id' => $single->id,
                'title' => 'رسالة',
                'body' => 'مرحباً.',
                'type' => 'custom',
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertSame(1, $single->notifications()->count());
    }

    public function test_an_audience_with_nobody_in_it_is_reported(): void
    {
        $subject = $this->createSubject();

        Livewire::test(CreateNotification::class)
            ->fillForm([
                'audience' => NotificationResource::AUDIENCE_SUBJECT,
                'audience_subject_id' => $subject->id,
                'title' => 'إعلان',
                'body' => 'نص',
                'type' => 'custom',
            ])
            ->call('create')
            ->assertHasFormErrors(['audience']);

        $this->assertSame(0, AppNotification::query()->count());
    }
}
