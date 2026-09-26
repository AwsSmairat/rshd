<?php

namespace Tests\Feature\Filament;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\InstructorResource\Pages\CreateInstructor;
use App\Models\User;
use App\Services\InstructorInvitationService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Mockery;
use Symfony\Component\Mailer\Exception\TransportException;
use Tests\TestCase;

class CreateInstructorMailFailureTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_smtp_failure_does_not_turn_successful_instructor_creation_into_server_error(): void
    {
        $admin = $this->createAdmin();
        $this->actingAs($admin);

        $invitationService = Mockery::mock(InstructorInvitationService::class);
        $invitationService
            ->shouldReceive('sendInvitation')
            ->once()
            ->andThrow(new TransportException('SMTP authentication failed'));

        $this->app->instance(InstructorInvitationService::class, $invitationService);

        Livewire::test(CreateInstructor::class)
            ->fillForm([
                'name' => 'Mail Failure Instructor',
                'email' => 'mail-failure-instructor@rshd.test',
                'status' => UserStatus::Active->value,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $instructor = User::query()
            ->where('email', 'mail-failure-instructor@rshd.test')
            ->first();

        $this->assertNotNull($instructor);
        $this->assertSame(UserRole::Instructor, $instructor->role);
        $this->assertNull($instructor->invitation_sent_at);
    }

    private function createAdmin(): User
    {
        $admin = User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
            'password_set_at' => now(),
        ]);

        $admin->assignRole(UserRole::Admin->value);

        return $admin;
    }
}
