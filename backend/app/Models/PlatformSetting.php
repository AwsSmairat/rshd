<?php

namespace App\Models;

use App\Services\PlatformSettingsService;
use Illuminate\Database\Eloquent\Model;

class PlatformSetting extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'group',
        'key',
        'value',
        'type',
        'is_public',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_public' => 'boolean',
        ];
    }

    public static function service(): PlatformSettingsService
    {
        return app(PlatformSettingsService::class);
    }

    /** @deprecated Use PlatformSettingsService::get() */
    public static function getValue(string $key, ?string $default = null): ?string
    {
        $value = static::service()->get($key, $default);

        return is_scalar($value) || $value === null ? (string) $value : json_encode($value);
    }

    /** @deprecated Use PlatformSettingsService::set() */
    public static function setValue(string $key, ?string $value): void
    {
        static::service()->set($key, $value);
    }

    /** @deprecated Use PlatformSettingsService::setGroup() */
    public static function setMany(array $values): void
    {
        static::service()->setGroup('platform', $values);
    }

    /** @deprecated Use PlatformSettingsService::definitions()['platform'] */
    public static function defaults(): array
    {
        $definitions = static::service()->definitions()['platform'] ?? [];
        $defaults = [];

        foreach ($definitions as $key => $definition) {
            $defaults[$key] = $definition['value'];
        }

        return $defaults;
    }
}
