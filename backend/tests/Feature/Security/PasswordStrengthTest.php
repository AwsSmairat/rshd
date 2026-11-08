<?php

namespace Tests\Feature\Security;

use App\Services\PlatformSettingsService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Group;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * Every password needs 9+ characters, an uppercase letter, a digit and a
 * special character, and the error says which of these are missing.
 */
#[Group('security')]
class PasswordStrengthTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    /**
     * @return array<string, array{string, list<string>}>
     */
    public static function weakPasswords(): array
    {
        return [
            'too short' => ['Ab1!xyz', ['9 أحرف على الأقل']],
            'no uppercase' => ['abcdefg1!', ['حرف إنجليزي كبير (A-Z)']],
            'no number' => ['Abcdefgh!', ['رقم (0-9)']],
            'no special character' => ['Abcdefgh1', ['رمز خاص مثل ! @ # $']],
            'several missing' => ['abc', ['9 أحرف على الأقل', 'حرف إنجليزي كبير (A-Z)', 'رقم (0-9)', 'رمز خاص مثل ! @ # $']],
        ];
    }

    /**
     * @param  list<string>  $expected
     */
    #[DataProvider('weakPasswords')]
    public function test_weak_passwords_are_named_for_what_they_lack(string $password, array $expected): void
    {
        $this->assertSame($expected, $this->plain(app(PlatformSettingsService::class)->passwordProblems($password)));
    }

    public function test_a_strong_password_passes(): void
    {
        $this->assertSame([], app(PlatformSettingsService::class)->passwordProblems('Rshd@2026x'));
    }

    public function test_the_setting_cannot_lower_the_minimum(): void
    {
        $settings = app(PlatformSettingsService::class);
        $settings->set('password_min_length', 6, 'security');

        $this->assertSame(PlatformSettingsService::PASSWORD_MIN_LENGTH, $settings->passwordMinLength());
    }

    public function test_changing_the_password_in_the_app_enforces_the_rule(): void
    {
        $student = $this->createStudent(['password' => Hash::make('Current@2026')]);
        Sanctum::actingAs($student);

        $this->patchJson('/api/v1/student/password', [
            'current_password' => 'Current@2026',
            'password' => 'weakpass1',
            'password_confirmation' => 'weakpass1',
        ])
            ->assertUnprocessable()
            ->assertJsonFragment(['كلمة المرور يجب أن تحتوي على: حرف إنجليزي كبير '."\u{2066}(A-Z)\u{2069}".'، رمز خاص مثل '."\u{2066}! @ # \$\u{2069}".'.']);
    }

    public function test_registering_enforces_the_rule(): void
    {
        $this->postJson('/api/v1/register', [
            'name' => 'طالب جديد',
            'email' => 'new-student@rshd.test',
            'password' => 'short',
            'password_confirmation' => 'short',
        ])->assertUnprocessable();
    }

    /**
     * Drops the direction marks that keep "(A-Z)" in order inside Arabic.
     *
     * @param  list<string>  $problems
     * @return list<string>
     */
    private function plain(array $problems): array
    {
        return array_map(fn (string $p): string => str_replace(["\u{2066}", "\u{2069}"], '', $p), $problems);
    }
}
