<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\User;
use App\Services\InstructorInvitationService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class InstructorSetPasswordPageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_valid_invitation_shows_styled_set_password_form(): void
    {
        [$instructor, $token] = $this->inviteInstructor();

        $this->get(route('instructor.set-password.show', [
            'email' => $instructor->email,
            'token' => $token,
        ]))
            ->assertOk()
            ->assertSee('تعيين كلمة المرور', false)
            ->assertSee('حساب المدرّس', false)
            ->assertSee($instructor->email, false)
            ->assertSee('كلمة المرور الجديدة', false)
            ->assertSee('تأكيد كلمة المرور', false)
            ->assertSee('حفظ كلمة المرور', false)
            ->assertSee('شروط كلمة المرور', false)
            ->assertDontSee('الرابط غير صالح', false);
    }

    public function test_invalid_invitation_shows_styled_error_instead_of_form(): void
    {
        $instructor = $this->createInstructor();

        $this->get(route('instructor.set-password.show', [
            'email' => $instructor->email,
            'token' => 'invalid-token',
        ]))
            ->assertOk()
            ->assertSee('الرابط غير صالح', false)
            ->assertSee('العودة لتسجيل الدخول', false)
            ->assertDontSee('حفظ كلمة المرور', false);
    }

    public function test_instructor_can_set_password_and_is_redirected_to_login(): void
    {
        [$instructor, $token] = $this->inviteInstructor();

        $this->from(route('instructor.set-password.show', [
            'email' => $instructor->email,
            'token' => $token,
        ]))->post(route('instructor.set-password.store'), [
            'email' => $instructor->email,
            'token' => $token,
            'password' => 'Newpassword1',
            'password_confirmation' => 'Newpassword1',
        ])
            ->assertRedirect('/admin/login')
            ->assertSessionHas('success');

        $this->assertTrue(Hash::check('Newpassword1', $instructor->fresh()->password));
    }

    public function test_password_confirmation_mismatch_returns_to_form(): void
    {
        [$instructor, $token] = $this->inviteInstructor();

        $this->from(route('instructor.set-password.show', [
            'email' => $instructor->email,
            'token' => $token,
        ]))->post(route('instructor.set-password.store'), [
            'email' => $instructor->email,
            'token' => $token,
            'password' => 'Newpassword1',
            'password_confirmation' => 'Mismatch1',
        ])
            ->assertRedirect()
            ->assertSessionHasErrors('password');
    }

    /**
     * @return array{0: User, 1: string}
     */
    private function inviteInstructor(): array
    {
        $instructor = $this->createInstructor();
        $token = app(InstructorInvitationService::class)->createInvitation($instructor);

        return [$instructor, $token];
    }

    private function createInstructor(): User
    {
        return User::factory()->create([
            'email' => 'instructor-invite@rshd.test',
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
            'password_set_at' => null,
        ]);
    }
}
