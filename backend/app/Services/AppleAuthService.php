<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\User;
use App\Services\Concerns\ResolvesOAuthStudentAccounts;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class AppleAuthService
{
    use ResolvesOAuthStudentAccounts;

    /**
     * @return array{
     *     apple_id: string,
     *     email: string|null,
     *     name: string,
     *     email_verified: bool
     * }
     */
    public function verifyIdentityToken(string $identityToken): array
    {
        $parts = explode('.', $identityToken);
        if (count($parts) !== 3) {
            throw new RuntimeException('رمز Apple غير صالح.');
        }

        [$encodedHeader, $encodedPayload, $encodedSignature] = $parts;

        /** @var array<string, mixed> $header */
        $header = json_decode($this->base64UrlDecode($encodedHeader), true, 512, JSON_THROW_ON_ERROR);

        /** @var array<string, mixed> $payload */
        $payload = json_decode($this->base64UrlDecode($encodedPayload), true, 512, JSON_THROW_ON_ERROR);

        $kid = (string) ($header['kid'] ?? '');
        if ($kid === '') {
            throw new RuntimeException('رمز Apple غير صالح.');
        }

        $publicKey = $this->resolvePublicKey($kid);
        $signedData = $encodedHeader.'.'.$encodedPayload;
        $signature = $this->base64UrlDecode($encodedSignature);

        $verified = openssl_verify(
            $signedData,
            $signature,
            $publicKey,
            OPENSSL_ALGO_SHA256,
        );

        if ($verified !== 1) {
            throw new RuntimeException('رمز Apple غير صالح.');
        }

        $issuer = (string) ($payload['iss'] ?? '');
        if ($issuer !== 'https://appleid.apple.com') {
            throw new RuntimeException('رمز Apple غير موثوق.');
        }

        $audience = (string) ($payload['aud'] ?? '');
        $allowedClientIds = config('services.apple.client_ids', []);
        if ($allowedClientIds !== [] && ! in_array($audience, $allowedClientIds, true)) {
            throw new RuntimeException('رمز Apple غير مصرح به لهذا التطبيق.');
        }

        $expiresAt = (int) ($payload['exp'] ?? 0);
        if ($expiresAt > 0 && $expiresAt < time()) {
            throw new RuntimeException('انتهت صلاحية رمز Apple.');
        }

        $appleId = (string) ($payload['sub'] ?? '');
        if ($appleId === '') {
            throw new RuntimeException('تعذر قراءة بيانات حساب Apple.');
        }

        $email = isset($payload['email']) ? (string) $payload['email'] : null;
        if ($email === '') {
            $email = null;
        }

        $emailVerified = filter_var($payload['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN);
        $name = $email !== null ? (strstr($email, '@', true) ?: 'Student') : 'Student';

        return [
            'apple_id' => $appleId,
            'email' => $email,
            'name' => $name,
            'email_verified' => $emailVerified || $email !== null,
        ];
    }

    /**
     * @param  array{
     *     apple_id: string,
     *     email: string|null,
     *     name: string,
     *     email_verified: bool
     * }  $appleProfile
     * @param  array{name?: string|null}  $profileHints
     */
    public function resolveStudentUser(array $appleProfile, array $profileHints = []): User
    {
        $displayName = trim((string) ($profileHints['name'] ?? ''));
        if ($displayName === '') {
            $displayName = $appleProfile['name'];
        }

        $user = User::query()
            ->where('apple_id', $appleProfile['apple_id'])
            ->first();

        if ($user !== null) {
            return $this->finalizeOAuthLogin($user, [
                'apple_id' => $appleProfile['apple_id'],
                'name' => $user->name ?: $displayName,
                'email_verified_at' => $user->email_verified_at ?? now(),
            ]);
        }

        if ($appleProfile['email'] !== null) {
            $existingByEmail = User::query()
                ->where('email', $appleProfile['email'])
                ->first();

            if ($existingByEmail !== null) {
                $this->rejectConflictingEmailAccount($existingByEmail, 'apple');
            }
        }

        if ($appleProfile['email'] === null) {
            throw new RuntimeException('تعذر إنشاء حساب جديد بدون بريد إلكتروني من Apple.');
        }

        if (! app(PlatformSettingsService::class)->studentRegistrationEnabled()) {
            throw new RuntimeException('التسجيل الذاتي للطلاب غير مفعّل حالياً.');
        }

        $user = User::query()->create([
            'name' => $displayName,
            'email' => $appleProfile['email'],
            'apple_id' => $appleProfile['apple_id'],
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
            'password' => null,
            'password_set_at' => null,
        ]);

        $user->assignRole('student');

        return $user;
    }

    private function resolvePublicKey(string $kid): string
    {
        /** @var array<string, mixed> $keys */
        $keys = Cache::remember('apple_auth_jwks', now()->addHours(12), function (): array {
            $response = Http::timeout(10)->get('https://appleid.apple.com/auth/keys');

            if (! $response->successful()) {
                throw new RuntimeException('تعذر التحقق من رمز Apple.');
            }

            return $response->json();
        });

        foreach ($keys['keys'] ?? [] as $jwk) {
            if (! is_array($jwk) || ($jwk['kid'] ?? null) !== $kid) {
                continue;
            }

            $pem = $this->jwkToPem($jwk);

            if ($pem !== null) {
                return $pem;
            }
        }

        throw new RuntimeException('تعذر التحقق من رمز Apple.');
    }

    /**
     * @param  array<string, mixed>  $jwk
     */
    private function jwkToPem(array $jwk): ?string
    {
        if (($jwk['kty'] ?? null) !== 'RSA') {
            return null;
        }

        $n = $this->base64UrlDecode((string) ($jwk['n'] ?? ''));
        $e = $this->base64UrlDecode((string) ($jwk['e'] ?? ''));

        if ($n === '' || $e === '') {
            return null;
        }

        $modulus = $this->encodeAsn1Integer($n);
        $exponent = $this->encodeAsn1Integer($e);
        $sequence = $this->encodeAsn1Sequence($modulus.$exponent);
        $bitString = "\x03".$this->encodeLength(strlen($sequence) + 1)."\x00".$sequence;
        $rsaOid = hex2bin('300D06092A864886F70D0101010500');
        $publicKeyInfo = $this->encodeAsn1Sequence($rsaOid.$bitString);

        return "-----BEGIN PUBLIC KEY-----\n"
            .chunk_split(base64_encode($publicKeyInfo), 64, "\n")
            ."-----END PUBLIC KEY-----\n";
    }

    private function base64UrlDecode(string $value): string
    {
        $remainder = strlen($value) % 4;
        if ($remainder > 0) {
            $value .= str_repeat('=', 4 - $remainder);
        }

        $decoded = base64_decode(strtr($value, '-_', '+/'), true);

        return $decoded === false ? '' : $decoded;
    }

    private function encodeAsn1Integer(string $value): string
    {
        if (ord($value[0]) > 0x7f) {
            $value = "\x00".$value;
        }

        return "\x02".$this->encodeLength(strlen($value)).$value;
    }

    private function encodeAsn1Sequence(string $value): string
    {
        return "\x30".$this->encodeLength(strlen($value)).$value;
    }

    private function encodeLength(int $length): string
    {
        if ($length < 0x80) {
            return chr($length);
        }

        $temp = ltrim(pack('N', $length), "\x00");
        if ($temp === '') {
            $temp = "\x00";
        }

        return chr(0x80 | strlen($temp)).$temp;
    }
}
