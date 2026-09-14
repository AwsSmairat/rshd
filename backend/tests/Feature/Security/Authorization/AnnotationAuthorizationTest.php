<?php

namespace Tests\Feature\Security\Authorization;


use PHPUnit\Framework\Attributes\Group;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class AnnotationAuthorizationTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_enrolled_student_can_read_and_store_annotations(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario();

        Sanctum::actingAs($student);

        $payload = ['annotation_json' => ['page' => 1, 'marks' => []]];

        $this->getJson('/api/v1/files/'.$file->id.'/annotations')
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->postJson('/api/v1/files/'.$file->id.'/annotations', $payload)
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.annotation_json.page', 1);
    }

    public function test_foreign_student_is_blocked_from_annotations(): void
    {
        [, $file] = $this->createEnrolledLessonFileScenario();
        $foreignStudent = $this->createStudent(['email' => 'foreign-annotations@rshd.test']);

        Sanctum::actingAs($foreignStudent);

        $this->getJson('/api/v1/files/'.$file->id.'/annotations')
            ->assertForbidden();

        $this->postJson('/api/v1/files/'.$file->id.'/annotations', [
            'annotation_json' => ['page' => 1],
        ])->assertForbidden();
    }

    public function test_expired_enrollment_is_blocked_from_annotations(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario(
            expiresAt: now()->subDay(),
        );

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/files/'.$file->id.'/annotations')
            ->assertForbidden();

        $this->postJson('/api/v1/files/'.$file->id.'/annotations', [
            'annotation_json' => ['page' => 1],
        ])->assertForbidden();
    }

    public function test_missing_file_returns_not_found(): void
    {
        $student = $this->createStudent();

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/files/999999/annotations')
            ->assertNotFound();
    }
}
