<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\LegalDocumentType;
use App\Http\Controllers\Controller;
use App\Services\LegalDocumentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LegalDocumentController extends Controller
{
    public function privacyPolicy(Request $request, LegalDocumentService $legalDocuments): JsonResponse
    {
        $language = $this->resolveLanguage($request);

        $document = $legalDocuments->findPublished(
            LegalDocumentType::PrivacyPolicy,
            $language,
        );

        if (! $document) {
            return $this->errorResponse('سياسة الخصوصية غير متاحة حاليًا.', 404);
        }

        return $this->successResponse($legalDocuments->toPublicPayload($document));
    }

    public function terms(Request $request, LegalDocumentService $legalDocuments): JsonResponse
    {
        $language = $this->resolveLanguage($request);

        $document = $legalDocuments->findPublished(
            LegalDocumentType::TermsAndConditions,
            $language,
        );

        if (! $document) {
            return $this->errorResponse('الشروط والأحكام غير متاحة حاليًا.', 404);
        }

        return $this->successResponse($legalDocuments->toPublicPayload($document));
    }

    protected function resolveLanguage(Request $request): string
    {
        $language = strtolower($request->string('language')->toString() ?: 'ar');

        return in_array($language, ['ar', 'en'], true) ? $language : 'ar';
    }
}
