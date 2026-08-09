<?php

namespace Tests\Feature\Security\Filament;

use App\Enums\ContentStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\SubjectResource;
use App\Models\Subject;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * @group security
 */
class FilamentInstructorScopeTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_instructor_query_excludes_other_instructors_subjects(): void
    {
        $instructorA = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
        ]);
        $instructorB = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
        ]);

        $ownSubject = Subject::query()->create([
            'instructor_id' => $instructorA->id,
            'title' => 'Own',
            'description' => 'd',
            'category' => SubjectCategory::General->value,
            'status' => ContentStatus::Active,
            'price' => 1,
        ]);
        $foreignSubject = Subject::query()->create([
            'instructor_id' => $instructorB->id,
            'title' => 'Foreign',
            'description' => 'd',
            'category' => SubjectCategory::General->value,
            'status' => ContentStatus::Active,
            'price' => 1,
        ]);

        $this->actingAs($instructorA);

        $ids = SubjectResource::getEloquentQuery()->pluck('id')->all();

        $this->assertContains($ownSubject->id, $ids);
        $this->assertNotContains($foreignSubject->id, $ids);
    }

    public function test_student_cannot_access_filament_panel(): void
    {
        $student = User::factory()->create([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
        ]);

        $this->actingAs($student)
            ->get('/admin')
            ->assertRedirect();
    }
}
