<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Mail\InstructorInvitationMail;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use InvalidArgumentException;

class InstructorInvitationService
{
    public function __construct(
        protected PlatformSettingsService $settings,
    ) {}

    public function createInvitation(User $instructor): string
    {
        $token = Str::random(64);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $instructor->email],
            [
                'token' => Hash::make($token),
                'created_at' => now(),
            ],
        );

        return $token;
    }

    public function sendInvitation(User $instructor): void
    {
        $token = $this->createInvitation($instructor);

        if ($this->settings->enabled('instructor_invitation_email_enabled', 'email')) {
            $this->settings->applyMailPreferences();
            Mail::to($instructor->email)->send(new InstructorInvitationMail($instructor, $token));
        }

        $instructor->update(['invitation_sent_at' => now()]);
    }

    public function resendInvitation(User $instructor): void
    {
        $this->sendInvitation($instructor);
    }

    public function setPassword(string $email, string $token, string $password): User
    {
        $instructor = User::query()
            ->where('email', $email)
            ->where('role', UserRole::Instructor)
            ->first();

        if ($instructor === null) {
            throw new InvalidArgumentException('Invalid instructor email.');
        }

        if (! $this->validateToken($email, $token)) {
            throw new InvalidArgumentException('Invalid or expired token.');
        }

        $instructor->update([
            'password' => $password,
            'password_set_at' => now(),
        ]);

        DB::table('password_reset_tokens')->where('email', $email)->delete();

        app(PlatformAuditService::class)->logAuth(
            'instructor.password_set',
            $instructor,
            'قام المدرس بتعيين كلمة المرور عبر الدعوة.',
            $instructor,
        );

        return $instructor->fresh();
    }

    public function validateToken(string $email, string $token): bool
    {
        $record = DB::table('password_reset_tokens')->where('email', $email)->first();

        if ($record === null) {
            return false;
        }

        if (! Hash::check($token, $record->token)) {
            return false;
        }

        if ($record->created_at === null) {
            return false;
        }

        $expiryHours = max(1, $this->settings->integer('instructor_invitation_expiry_hours', 72, 'security'));

        return Carbon::parse($record->created_at)
            ->addHours($expiryHours)
            ->isFuture();
    }

    public function invitationExpiryHours(): int
    {
        return max(1, $this->settings->integer('instructor_invitation_expiry_hours', 72, 'security'));
    }
}
