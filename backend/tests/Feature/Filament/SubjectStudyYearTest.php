<?php

namespace Tests\Feature\Filament;

use App\Enums\ContentStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\SubjectResource\Pages\CreateSubject;
use App\Filament\Resources\SubjectResource\Pages\EditSubject;
use App\Http\Resources\SubjectResource as SubjectApiResource;
use App\Models\Subject;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Livewire\Livewire;
use Tests\TestCase;

class SubjectStudyYearTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_study_year_field_only_appears_for_medicine(): void
    {
        $admin = $this->createAdmin();
        $this->actingAs($admin);

        Livewire::test(CreateSubject::class)
            ->assertFormFieldIsHidden('study_year')
            ->fillForm(['category' => SubjectCategory::Medicine->value])
            ->assertFormFieldIsVisible('study_year')
            ->fillForm(['category' => SubjectCategory::Engineering->value])
            ->assertFormFieldIsHidden('study_year');
    }

    public function test_medicine_subject_requires_and_saves_a_study_year(): void
    {
        $admin = $this->createAdmin();
        $this->actingAs($admin);

        Livewire::test(CreateSubject::class)
            ->fillForm($this->formData(SubjectCategory::Medicine, null, $admin))
            ->call('create')
            ->assertHasFormErrors(['study_year' => 'required']);

        Livewire::test(CreateSubject::class)
            ->fillForm($this->formData(SubjectCategory::Medicine, 3, $admin))
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertSame(3, Subject::query()->where('title', 'Anatomy')->value('study_year'));
    }

    public function test_other_categories_save_without_a_year(): void
    {
        $admin = $this->createAdmin();
        $this->actingAs($admin);

        Livewire::test(CreateSubject::class)
            ->fillForm($this->formData(SubjectCategory::It, null, $admin))
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertNull(Subject::query()->where('title', 'Anatomy')->value('study_year'));
    }

    public function test_moving_a_subject_out_of_medicine_clears_its_year(): void
    {
        $admin = $this->createAdmin();
        $this->actingAs($admin);
        $subject = Subject::query()->create([
            'instructor_id' => $admin->id,
            'title' => 'Anatomy',
            'category' => SubjectCategory::Medicine->value,
            'study_year' => 2,
            'status' => ContentStatus::Active,
        ]);

        Livewire::test(EditSubject::class, ['record' => $subject->getRouteKey()])
            ->fillForm(['category' => SubjectCategory::General->value])
            ->call('save')
            ->assertHasNoFormErrors();

        $this->assertNull($subject->fresh()->study_year);
    }

    public function test_api_exposes_the_study_year(): void
    {
        $admin = $this->createAdmin();
        $subject = Subject::query()->create([
            'instructor_id' => $admin->id,
            'title' => 'Anatomy',
            'category' => SubjectCategory::Medicine->value,
            'study_year' => 4,
            'status' => ContentStatus::Active,
        ]);

        $payload = SubjectApiResource::make($subject)->toArray(Request::create('/'));

        $this->assertSame(4, $payload['study_year']);
    }

    /** @return array<string, mixed> */
    private function formData(SubjectCategory $category, ?int $year, User $admin): array
    {
        $instructor = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
        ]);

        return [
            'title' => 'Anatomy',
            'description' => 'وصف',
            'category' => $category->value,
            'study_year' => $year,
            'instructor_id' => $instructor->id,
            'status' => ContentStatus::Active->value,
            'price' => 10,
        ];
    }

    private function createAdmin(): User
    {
        $admin = User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
            'password_set_at' => now(),
        ]);
        $admin->assignRole(UserRole::Admin->value);

        return $admin;
    }
}
