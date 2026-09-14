<?php

namespace Tests\Feature\Security;


use PHPUnit\Framework\Attributes\Group;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class LessonFileSerializationTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_lesson_file_json_never_exposes_permanent_public_url(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario();

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/files/'.$file->id)
            ->assertOk()
            ->json('data');

        $this->assertNull($response['file_url'] ?? null);
        $this->assertTrue($response['requires_signed_download'] ?? false);
        $this->assertArrayNotHasKey('external_path', $response);
    }

    public function test_model_resolved_file_url_is_always_null(): void
    {
        [, $file] = $this->createEnrolledLessonFileScenario();

        $this->assertNull($file->resolvedFileUrl());
    }
}
