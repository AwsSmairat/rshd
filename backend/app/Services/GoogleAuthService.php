<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\User;
use App\Services\Concerns\ResolvesOAuthStudentAccounts;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class GoogleAuthService
{
    use ResolvesOAuthStudentAccounts;

    /**
     * @return array{
     *     google_id: string,
     *     email: string,
     *     name: string,
     *     email_verified: bool
     * }
     */
    public function verifyIdToken(string $idToken): array
    {
        $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if (! $response->successful()) {
            throw new RuntimeException('رمز Google غير صالح.');
        }

        /** @var array<string, mixed> $payload */
        $payload = $response->json();

        $audience = (string) ($payload['aud'] ?? '');
        $allowedClientIds = config('services.google.client_ids', []);

        if ($allowedClientIds !== [] && ! in_array($audience, $allowedClientIds, true)) {
            throw new RuntimeException('رمز Google غير مصرح به لهذا التطبيق.');
        }

        $emailVerified = filter_var($payload['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN);
        if (! $emailVerified) {
            throw new RuntimeException('يجب تأكيد بريد Google قبل المتابعة.');
        }

        $googleId = (string) ($payload['sub'] ?? '');
        $email = (string) ($payload['email'] ?? '');
        $name = trim((string) ($payload['name'] ?? ''));

        if ($googleId === '' || $email === '') {
            throw new RuntimeException('تعذر قراءة بيانات حساب Google.');
        }

        if ($name === '') {
            $name = strstr($email, '@', true) ?: 'Student';
        }

        $expiresAt = (int) ($payload['exp'] ?? 0);
        if ($expiresAt > 0 && $expiresAt < time()) {
            throw new RuntimeException('انتهت صلاحية رمز Google.');
        }

        return [
            'google_id' => $googleId,
            'email' => $email,
            'name' => $name,
            'email_verified' => $emailVerified,
        ];
    }

    /**
     * @param  array{
     *     google_id: string,
     *     email: string,
     *     name: string,
     *     email_verified: bool
     * }  $googleProfile
     */
    public function resolveStudentUser(array $googleProfile): User
    {
        $user = User::query()
            ->where('google_id', $googleProfile['google_id'])
            ->first();

        if ($user !== null) {
            return $this->finalizeOAuthLogin($user, [
                'google_id' => $googleProfile['google_id'],
                'name' => $user->name ?: $googleProfile['name'],
                'email_verified_at' => $user->email_verified_at ?? now(),
            ]);
        }

        $existingByEmail = User::query()
            ->where('email', $googleProfile['email'])
            ->first();

        if ($existingByEmail !== null) {
            $this->rejectConflictingEmailAccount($existingByEmail, 'google');
        }

        if (! app(PlatformSettingsService::class)->studentRegistrationEnabled()) {
            throw new RuntimeException('التسجيل الذاتي للطلاب غير مفعّل حالياً.');
        }

        $user = User::query()->create([
            'name' => $googleProfile['name'],
            'email' => $googleProfile['email'],
            'google_id' => $googleProfile['google_id'],
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
            'password' => null,
            'password_set_at' => null,
        ]);

        $user->assignRole('student');

        return $user;
    }
}
