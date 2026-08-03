<?php

namespace App\Services\Concerns;

use App\Enums\UserStatus;
use App\Models\User;
use RuntimeException;

trait ResolvesOAuthStudentAccounts
{
    protected function assertEligibleOAuthStudent(User $user): void
    {
        if (! $user->isStudent()) {
            throw new RuntimeException('هذا التطبيق مخصص للطلاب فقط.');
        }

        if ($user->status === UserStatus::Blocked) {
            throw new RuntimeException('الحساب موقوف.');
        }
    }

    protected function rejectConflictingEmailAccount(User $existing, string $attemptedProvider): void
    {
        if ($existing->google_id !== null && $attemptedProvider !== 'google') {
            throw new RuntimeException(
                'This account uses Google or Apple sign-in. Please continue with the original provider.',
            );
        }

        if ($existing->apple_id !== null && $attemptedProvider !== 'apple') {
            throw new RuntimeException(
                'This account uses Google or Apple sign-in. Please continue with the original provider.',
            );
        }

        if ($existing->hasSetPassword() || $existing->password !== null) {
            throw new RuntimeException(
                'An account with this email already exists. Please sign in with your email and password.',
            );
        }

        throw new RuntimeException(
            'An account with this email already exists. Please sign in with your original method.',
        );
    }

    /**
     * @param  array<string, mixed>  $updates
     */
    protected function finalizeOAuthLogin(User $user, array $updates): User
    {
        $this->assertEligibleOAuthStudent($user);

        $user->fill($updates);
        $user->save();

        return $user;
    }
}
