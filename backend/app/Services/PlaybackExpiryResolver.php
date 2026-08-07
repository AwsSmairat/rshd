<?php

namespace App\Services;

use App\Models\User;
use App\Models\Video;
use Illuminate\Support\Carbon;
use RuntimeException;

class PlaybackExpiryResolver
{
    public function __construct(
        protected EnrollmentService $enrollment,
    ) {}

    public function resolve(User $user, Video $video): Carbon
    {
        $ttl = max(60, (int) config('video.playback_ttl', 600));
        $expiresAt = now()->addSeconds($ttl);

        if ($user->isStudent()) {
            $video->loadMissing('lesson.subject');
            $subject = $video->lesson?->subject;

            if ($subject !== null) {
                $enrollmentExpiry = $this->enrollment->enrollmentExpiresAt($user, $subject);

                if ($enrollmentExpiry !== null && $enrollmentExpiry->lt($expiresAt)) {
                    $expiresAt = $enrollmentExpiry->copy();
                }
            }
        }

        if ($expiresAt->lte(now())) {
            throw new RuntimeException('Access window has expired.');
        }

        return $expiresAt;
    }
}
