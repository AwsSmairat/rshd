<?php

namespace App\Contracts;

use App\Models\User;
use App\Models\Video;
use Illuminate\Support\Carbon;

interface VideoProviderInterface
{
    /**
     * @return array{url: string, expires_at: Carbon}
     */
    public function generateSignedPlaybackUrl(Video $video, User $user): array;

    public function supports(Video $video): bool;
}
