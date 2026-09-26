<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\User;
use App\Services\InstructorInvitationService;
use App\Services\PlatformSettingsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class InstructorInvitationServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_disabled_invitation_email_does_not_mark_invitation_as_sent(): void
    {
        /** @var PlatformSettingsService $settings */
        $settings = app(PlatformSettingsService::class);
        $settings->set('instructor_invitation_email_enabled', false, 'email');

        Mail::fake();

        $instructor = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
            'password_set_at' => null,
            'invitation_sent_at' => null,
        ]);

        app(InstructorInvitationService::class)->sendInvitation($instructor);

        $this->assertNull($instructor->fresh()->invitation_sent_at);
        $this->assertTrue(
            DB::table('password_reset_tokens')->where('email', $instructor->email)->exists()
        );
        Mail::assertNothingSent();
    }
}
