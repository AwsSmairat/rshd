<?php

namespace Tests\Feature;

use App\Services\PlatformSettingsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class PublicSettingsContactTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();
    }

    public function test_public_settings_exposes_contact_channels_for_app(): void
    {
        /** @var PlatformSettingsService $settings */
        $settings = app(PlatformSettingsService::class);

        $settings->set('public_contact_email', 'contact@rshd.com', 'email');
        $settings->set('support_phone', '0799532264', 'platform');
        $settings->set('facebook_url', 'https://facebook.com/rshd', 'social');
        $settings->set('instagram_url', 'https://instagram.com/rshdacademy', 'social');
        $settings->set('whatsapp_number', '962799532264', 'social');

        $this->getJson('/api/v1/settings/public')
            ->assertOk()
            ->assertJsonPath('data.contact.email', 'contact@rshd.com')
            ->assertJsonPath('data.contact.phone', '0799532264')
            ->assertJsonPath('data.contact.facebook_url', 'https://facebook.com/rshd')
            ->assertJsonPath('data.contact.instagram_url', 'https://instagram.com/rshdacademy')
            ->assertJsonPath('data.contact.whatsapp_number', '962799532264')
            ->assertJsonPath('data.support_phone', '0799532264');
    }
}
