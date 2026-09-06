<?php

namespace Tests\Feature;

use App\Services\PlatformSettingsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class PlatformSettingsPreferencesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();
    }

    public function test_mail_and_security_preferences_apply_from_admin_updates(): void
    {
        /** @var PlatformSettingsService $settings */
        $settings = app(PlatformSettingsService::class);

        $settings->set('sender_display_name', 'RSHD Mail', 'email');
        $settings->set('reply_to_email', 'reply@rshd.test', 'email');
        $settings->set('session_lifetime_minutes', 90, 'security');

        $settings->applyMailPreferences();
        $settings->applySecurityPreferences();

        $this->assertSame('RSHD Mail', config('mail.from.name'));
        $this->assertSame('reply@rshd.test', config('mail.reply_to.address'));
        $this->assertSame(90, config('session.lifetime'));
        $this->assertSame(90, config('sanctum.expiration'));

        $settings->set('sender_display_name', 'RSHD Updated', 'email');
        $settings->set('session_lifetime_minutes', 45, 'security');
        $settings->applyMailPreferences();
        $settings->applySecurityPreferences();

        $this->assertSame('RSHD Updated', config('mail.from.name'));
        $this->assertSame(45, config('session.lifetime'));
        $this->assertSame(45, config('sanctum.expiration'));
    }

    public function test_cached_settings_reads_skip_schema_and_table_queries(): void
    {
        /** @var PlatformSettingsService $settings */
        $settings = app(PlatformSettingsService::class);

        $settings->set('sender_display_name', 'RSHD Mail', 'email');
        $settings->set('reply_to_email', 'reply@rshd.test', 'email');
        $settings->set('session_lifetime_minutes', 90, 'security');
        $settings->get('sender_display_name', null, 'email');
        $settings->get('reply_to_email', null, 'email');
        $settings->get('session_lifetime_minutes', null, 'security');

        DB::flushQueryLog();
        DB::enableQueryLog();

        $settings->applyMailPreferences();
        $settings->applySecurityPreferences();

        $queries = collect(DB::getQueryLog())
            ->pluck('query')
            ->filter(function (string $sql): bool {
                $sql = strtolower($sql);

                return str_contains($sql, 'platform_settings')
                    || str_contains($sql, 'sqlite_master')
                    || str_contains($sql, 'information_schema');
            })
            ->values()
            ->all();

        $this->assertSame([], $queries);
    }

    public function test_apply_preferences_survive_missing_cache_table(): void
    {
        config(['cache.default' => 'database']);
        Schema::dropIfExists('cache');

        /** @var PlatformSettingsService $settings */
        $settings = app(PlatformSettingsService::class);

        $settings->applyMailPreferences();
        $settings->applySecurityPreferences();

        $this->assertSame('RSHD', config('mail.from.name'));
        $this->assertGreaterThanOrEqual(5, (int) config('session.lifetime'));
    }
}
