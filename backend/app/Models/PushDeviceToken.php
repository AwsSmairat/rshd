<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Laravel\Sanctum\PersonalAccessToken;

class PushDeviceToken extends Model
{
    public const PLATFORM_IOS = 'ios';

    public const PLATFORM_ANDROID = 'android';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'user_id',
        'personal_access_token_id',
        'token_hash',
        'token',
        'platform',
        'device_id',
        'app_version',
        'last_registered_at',
    ];

    /**
     * @var list<string>
     */
    protected $hidden = ['token', 'token_hash'];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'token' => 'encrypted',
            'last_registered_at' => 'datetime',
        ];
    }

    public static function hashToken(string $token): string
    {
        return hash('sha256', $token);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return BelongsTo<PersonalAccessToken, $this>
     */
    public function accessToken(): BelongsTo
    {
        return $this->belongsTo(PersonalAccessToken::class, 'personal_access_token_id');
    }
}
