<?php

namespace Tests\Feature;

use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

class StudentAvatarTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Storage::fake('public');
    }

    public function test_uploaded_avatar_is_served_through_the_authenticated_api(): void
    {
        $student = $this->createStudent(['email' => 'avatar-owner@rshd.test']);
        Sanctum::actingAs($student);

        $upload = $this->post('/api/v1/student/avatar', [
            'avatar' => UploadedFile::fake()->image('photo.jpg', 80, 80),
        ])->assertOk();

        $avatarUrl = $upload->json('data.profile.avatar_url');
        $this->assertNotNull($avatarUrl);
        $this->assertStringContainsString('/api/v1/student/avatar', (string) $avatarUrl);
        $this->assertStringNotContainsString('/storage/student-avatars', (string) $avatarUrl);

        $this->get('/api/v1/student/avatar')
            ->assertOk()
            ->assertHeader('content-type', 'image/jpeg');
    }

    public function test_missing_avatar_returns_not_found(): void
    {
        $student = $this->createStudent(['email' => 'avatar-missing@rshd.test']);
        Sanctum::actingAs($student);

        $this->get('/api/v1/student/avatar')->assertNotFound();
    }

    public function test_anonymous_user_cannot_read_avatar(): void
    {
        $this->getJson('/api/v1/student/avatar')->assertUnauthorized();
    }
}
