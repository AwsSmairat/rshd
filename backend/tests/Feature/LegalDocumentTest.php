<?php

namespace Tests\Feature;

use App\Enums\LegalDocumentStatus;
use App\Enums\LegalDocumentType;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\LegalDocument;
use App\Models\LegalDocumentAcceptance;
use App\Models\User;
use App\Services\LegalDocumentService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LegalDocumentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Cache::flush();
    }

    public function test_public_privacy_returns_published_version_only(): void
    {
        $published = $this->createPublishedDocument(LegalDocumentType::PrivacyPolicy, '1.0');
        $this->createDraftDocument(LegalDocumentType::PrivacyPolicy, '2.0');

        $this->getJson('/api/v1/legal/privacy-policy')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.type', 'privacy_policy')
            ->assertJsonPath('data.version', '1.0')
            ->assertJsonPath('data.title', $published->title)
            ->assertJsonStructure(['data' => ['sections']]);
    }

    public function test_public_terms_returns_published_version_only(): void
    {
        $this->createPublishedDocument(LegalDocumentType::TermsAndConditions, '1.0', requiresAcceptance: true);

        $this->getJson('/api/v1/legal/terms')
            ->assertOk()
            ->assertJsonPath('data.type', 'terms_and_conditions')
            ->assertJsonPath('data.requires_acceptance', true);
    }

    public function test_draft_and_superseded_documents_are_not_public(): void
    {
        $this->createDraftDocument(LegalDocumentType::PrivacyPolicy, '1.0');

        $this->getJson('/api/v1/legal/privacy-policy')
            ->assertStatus(404);
    }

    public function test_publishing_new_version_supersedes_old_and_clears_cache(): void
    {
        /** @var LegalDocumentService $service */
        $service = app(LegalDocumentService::class);

        $old = $this->createPublishedDocument(LegalDocumentType::TermsAndConditions, '1.0');
        $service->findPublished(LegalDocumentType::TermsAndConditions);

        $draft = $service->createDraft([
            'type' => LegalDocumentType::TermsAndConditions,
            'title' => 'الشروط v2',
            'sections' => $this->sampleSections(),
            'version' => '2.0',
            'language' => 'ar',
            'requires_acceptance' => true,
        ]);

        $service->publish($draft);

        $this->assertSame(LegalDocumentStatus::Superseded, $old->fresh()->status);
        $this->assertSame('2.0', $service->findPublished(LegalDocumentType::TermsAndConditions)?->version);

        $this->getJson('/api/v1/legal/terms')
            ->assertJsonPath('data.version', '2.0');
    }

    public function test_terms_status_requires_acceptance_for_new_version(): void
    {
        $student = $this->createStudent(['terms_accepted_version' => '1.0']);
        $this->createPublishedDocument(LegalDocumentType::TermsAndConditions, '2.0', requiresAcceptance: true);

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/student/terms/status')
            ->assertOk()
            ->assertJsonPath('data.accepted', false)
            ->assertJsonPath('data.accepted_version', '1.0')
            ->assertJsonPath('data.current_version', '2.0')
            ->assertJsonPath('data.requires_acceptance', true);
    }

    public function test_terms_status_after_acceptance(): void
    {
        $document = $this->createPublishedDocument(
            LegalDocumentType::TermsAndConditions,
            '2.0',
            requiresAcceptance: true,
        );
        $student = $this->createStudent();

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/student/terms/accept', ['platform' => 'flutter'])
            ->assertOk()
            ->assertJsonPath('data.accepted', true)
            ->assertJsonPath('data.current_version', '2.0')
            ->assertJsonPath('data.requires_acceptance', false);

        $this->assertDatabaseHas('legal_document_acceptances', [
            'user_id' => $student->id,
            'legal_document_id' => $document->id,
            'version' => '2.0',
        ]);

        $this->assertSame('2.0', $student->fresh()->terms_accepted_version);
    }

    public function test_minor_terms_update_without_requires_acceptance_does_not_force_reacceptance(): void
    {
        $student = $this->createStudent(['terms_accepted_version' => '1.0']);
        $this->createPublishedDocument(LegalDocumentType::TermsAndConditions, '1.1', requiresAcceptance: false);

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/student/terms/status')
            ->assertJsonPath('data.requires_acceptance', false);
    }

    public function test_student_cannot_accept_when_already_on_current_version(): void
    {
        $this->createPublishedDocument(LegalDocumentType::TermsAndConditions, '1.0', requiresAcceptance: true);
        $student = $this->createStudent(['terms_accepted_version' => '1.0']);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/student/terms/accept')
            ->assertOk()
            ->assertJsonPath('data.requires_acceptance', false);

        $this->assertSame(0, LegalDocumentAcceptance::count());
    }

    public function test_acceptance_uses_authenticated_user_not_request_body(): void
    {
        $document = $this->createPublishedDocument(
            LegalDocumentType::TermsAndConditions,
            '1.0',
            requiresAcceptance: true,
        );
        $student = $this->createStudent();
        $other = $this->createStudent(['email' => 'other@rshdacademy.com']);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/student/terms/accept', [
            'user_id' => $other->id,
        ])->assertOk();

        $this->assertDatabaseHas('legal_document_acceptances', [
            'user_id' => $student->id,
            'legal_document_id' => $document->id,
        ]);

        $this->assertDatabaseMissing('legal_document_acceptances', [
            'user_id' => $other->id,
        ]);
    }

    public function test_non_student_cannot_access_terms_endpoints(): void
    {
        $admin = User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
        ]);

        Sanctum::actingAs($admin);

        $this->getJson('/api/v1/student/terms/status')->assertForbidden();
        $this->postJson('/api/v1/student/terms/accept')->assertForbidden();
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    protected function createStudent(array $overrides = []): User
    {
        $student = User::factory()->create(array_merge([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ], $overrides));

        $student->assignRole('student');

        return $student;
    }

    protected function createPublishedDocument(
        LegalDocumentType $type,
        string $version,
        bool $requiresAcceptance = false,
    ): LegalDocument {
        /** @var LegalDocumentService $service */
        $service = app(LegalDocumentService::class);

        $document = $service->createDraft([
            'type' => $type,
            'title' => $type->label(),
            'subtitle' => 'وصف',
            'sections' => $this->sampleSections(),
            'version' => $version,
            'language' => 'ar',
            'requires_acceptance' => $requiresAcceptance,
        ]);

        return $service->publish($document);
    }

    protected function createDraftDocument(LegalDocumentType $type, string $version): LegalDocument
    {
        /** @var LegalDocumentService $service */
        $service = app(LegalDocumentService::class);

        return $service->createDraft([
            'type' => $type,
            'title' => $type->label(),
            'sections' => $this->sampleSections(),
            'version' => $version,
            'language' => 'ar',
        ]);
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    protected function sampleSections(): array
    {
        return [
            [
                'id' => 'intro',
                'title' => 'مقدمة',
                'icon' => 'info_outline',
                'paragraphs' => ['نص تجريبي'],
                'bullet_points' => [],
                'subsections' => [],
            ],
        ];
    }
}
