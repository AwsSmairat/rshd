<?php

namespace App\Http\Controllers;

use App\Enums\LegalDocumentType;
use App\Services\LegalDocumentService;
use App\Services\PlatformSettingsService;
use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;

class PublicLegalController extends Controller
{
    public function privacy(Request $request, LegalDocumentService $legalDocuments): View
    {
        return $this->document(
            $request,
            $legalDocuments,
            LegalDocumentType::PrivacyPolicy,
        );
    }

    public function terms(Request $request, LegalDocumentService $legalDocuments): View
    {
        return $this->document(
            $request,
            $legalDocuments,
            LegalDocumentType::TermsAndConditions,
        );
    }

    public function accountDeletion(PlatformSettingsService $settings): View
    {
        $contactEmail = $settings->stringValue("public_contact_email", "", "email");

        if ($contactEmail === "") {
            $contactEmail = $settings->stringValue("support_email", "", "email");
        }

        return view("legal.account-deletion", [
            "contactEmail" => $contactEmail,
        ]);
    }

    protected function document(
        Request $request,
        LegalDocumentService $legalDocuments,
        LegalDocumentType $type,
    ): View {
        $language = strtolower(
            $request->string('language')->toString()
                ?: LegalDocumentService::DEFAULT_LANGUAGE
        );

        if (! in_array($language, ['ar', 'en'], true)) {
            $language = LegalDocumentService::DEFAULT_LANGUAGE;
        }

        $document = $legalDocuments->findPublished($type, $language);

        abort_if($document === null, 404);

        return view('legal.document', [
            'document' => $document,
            'type' => $type,
        ]);
    }
}
