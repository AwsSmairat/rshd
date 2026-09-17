<?php

namespace Tests\Feature;

use App\Enums\LegalDocumentType;
use App\Models\LegalDocument;
use App\Services\LegalDocumentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class PublicLegalPagesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::flush();
    }

    public function test_public_legal_route_names_are_registered(): void
    {
        $router = app('router');

        $this->assertTrue($router->has('legal.privacy'));
        $this->assertTrue($router->has('legal.terms'));
        $this->assertTrue($router->has('legal.account-deletion'));
    }

    public function test_privacy_page_renders_published_document_and_not_newer_draft(): void
    {
        $published = $this->createPublishedDocument(
            LegalDocumentType::PrivacyPolicy,
            '1.0',
            'سياسة الخصوصية المنشورة',
            'محتوى الخصوصية المنشور',
        );

        $draft = $this->createDraftDocument(
            LegalDocumentType::PrivacyPolicy,
            '2.0',
            'مسودة الخصوصية غير المنشورة',
            'محتوى مسودة غير منشور',
        );

        $this->get(route('legal.privacy'))
            ->assertOk()
            ->assertSee($published->title)
            ->assertSee('محتوى الخصوصية المنشور')
            ->assertDontSee($draft->title)
            ->assertDontSee('محتوى مسودة غير منشور')
            ->assertSee('dir="rtl"', false);
    }

    public function test_terms_page_renders_published_document_and_not_newer_draft(): void
    {
        $published = $this->createPublishedDocument(
            LegalDocumentType::TermsAndConditions,
            '1.0',
            'الشروط والأحكام المنشورة',
            'محتوى الشروط المنشور',
        );

        $draft = $this->createDraftDocument(
            LegalDocumentType::TermsAndConditions,
            '2.0',
            'مسودة الشروط غير المنشورة',
            'محتوى مسودة شروط غير منشور',
        );

        $this->get(route('legal.terms'))
            ->assertOk()
            ->assertSee($published->title)
            ->assertSee('محتوى الشروط المنشور')
            ->assertDontSee($draft->title)
            ->assertDontSee('محتوى مسودة شروط غير منشور')
            ->assertSee('dir="rtl"', false);
    }

    public function test_missing_published_documents_return_404(): void
    {
        $this->get(route('legal.privacy'))->assertNotFound();
        $this->get(route('legal.terms'))->assertNotFound();
    }

    public function test_unsupported_language_falls_back_to_default_arabic(): void
    {
        $published = $this->createPublishedDocument(
            LegalDocumentType::PrivacyPolicy,
            '1.0',
            'سياسة عربية',
            'محتوى عربي',
        );

        $this->get(route('legal.privacy', ['language' => 'fr']))
            ->assertOk()
            ->assertSee($published->title)
            ->assertSee('محتوى عربي');
    }

    public function test_supported_language_without_published_document_returns_404(): void
    {
        $this->createPublishedDocument(
            LegalDocumentType::PrivacyPolicy,
            '1.0',
            'سياسة عربية',
            'محتوى عربي',
        );

        $this->get(route('legal.privacy', ['language' => 'en']))
            ->assertNotFound();
    }

    public function test_account_deletion_page_uses_official_contact_email_and_valid_mailto(): void
    {
        $this->get(route('legal.account-deletion'))
            ->assertOk()
            ->assertSee('admin@rshdacademy.com')
            ->assertDontSee('rshdacademy@gmail.com')
            ->assertSee('mailto:admin@rshdacademy.com?subject=', false)
            ->assertSee('&amp;body=', false)
            ->assertSee('لا ترسل كلمة المرور')
            ->assertSee('30 يوم عمل')
            ->assertSee(route('legal.privacy'), false);
    }

    public function test_legal_document_output_does_not_render_untrusted_html(): void
    {
        $this->createPublishedDocument(
            LegalDocumentType::PrivacyPolicy,
            '1.0',
            '<script>alert("title")</script>',
            '<img src=x onerror=alert(1)>Safe & sound',
            'intro"><script>alert(1)</script>',
            'قسم & <b>آمن</b>',
        );

        $response = $this->get(route('legal.privacy'));

        $response
            ->assertOk()
            ->assertDontSee('<script>', false)
            ->assertDontSee('onerror=alert(1)', false)
            ->assertSee('&lt;script&gt;alert(&quot;title&quot;)&lt;/script&gt;', false)
            ->assertSee('Safe &amp; sound', false)
            ->assertSee('قسم &amp; آمن', false)
            ->assertSee('id="intro&quot;&gt;alert(1)"', false);
    }

    protected function createPublishedDocument(
        LegalDocumentType $type,
        string $version,
        string $title,
        string $paragraph,
        string $sectionId = 'intro',
        string $sectionTitle = 'مقدمة',
    ): LegalDocument {
        $document = $this->createDraftDocument(
            $type,
            $version,
            $title,
            $paragraph,
            $sectionId,
            $sectionTitle,
        );

        return app(LegalDocumentService::class)->publish($document);
    }

    protected function createDraftDocument(
        LegalDocumentType $type,
        string $version,
        string $title,
        string $paragraph,
        string $sectionId = 'intro',
        string $sectionTitle = 'مقدمة',
    ): LegalDocument {
        return app(LegalDocumentService::class)->createDraft([
            'type' => $type,
            'title' => $title,
            'subtitle' => 'وصف',
            'summary' => 'ملخص',
            'sections' => [
                [
                    'id' => $sectionId,
                    'title' => $sectionTitle,
                    'icon' => 'info_outline',
                    'paragraphs' => [$paragraph],
                    'bullet_points' => [],
                    'subsections' => [],
                ],
            ],
            'version' => $version,
            'language' => 'ar',
            'requires_acceptance' => false,
        ]);
    }
}
