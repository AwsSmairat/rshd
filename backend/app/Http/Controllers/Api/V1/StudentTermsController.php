<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\TermsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentTermsController extends Controller
{
    public function status(Request $request, TermsService $terms): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذه الخدمة متاحة للطلاب فقط.');
        }

        return $this->successResponse($terms->acceptanceStatus($user));
    }

    public function accept(Request $request, TermsService $terms): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذه الخدمة متاحة للطلاب فقط.');
        }

        if (! $terms->userRequiresAcceptance($user) &&
            $user->terms_accepted_version === $terms->currentVersion()) {
            return $this->successResponse(
                $terms->acceptanceStatus($user),
                'سبق تسجيل موافقتك على هذه النسخة.',
            );
        }

        $platform = $request->string('platform')->toString()
            ?: $request->header('X-App-Platform')
            ?: 'flutter';

        try {
            $updated = $terms->recordAcceptance($user, $platform, $request);
        } catch (\InvalidArgumentException $exception) {
            return $this->errorResponse($exception->getMessage(), 422);
        }

        return $this->successResponse(
            $terms->acceptanceStatus($updated),
            'تم تسجيل موافقتك على الشروط والأحكام.',
        );
    }
}
