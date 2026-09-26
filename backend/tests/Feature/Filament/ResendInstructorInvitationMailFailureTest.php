<?php

namespace Tests\Feature\Filament;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\InstructorResource\Pages\ListInstructors;
use App\Models\User;
use App\Services\InstructorInvitationService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Mockery;
use Symfony\Component\Mailer\Exception\TransportException;
use Tests\TestCase;

class ResendInstructorInvitationMailFailureTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_smtp_failure_does_not_turn_resend_action_into_server_error(): void
    {
        $admin = $this->createAdmin();
        $instructor = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
            'password_set_at' => null,
            'invitation_sent_at' => null,
        ]);

        $this->actingAs($admin);

        $invitationService = Mockery::mock(InstructorInvitationService::class);
        $invitationService
            ->shouldReceive('resendInvitation')
            ->once()
            ->with(Mockery::on(fn (User $user): bool => $user->is($instructor)))
            ->andThrow(new TransportException('SMTP authentication failed'));

        $this->app->instance(InstructorInvitationService::class, $invitationService);

        Livewire::test(ListInstructors::class)
            ->callTableAction('resendInvitation', $instructor)
            ->assertHasNoTableActionErrors();

        $this->assertNull($instructor->fresh()->invitation_sent_at);
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
