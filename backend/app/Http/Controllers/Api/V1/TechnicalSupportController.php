<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\SendSupportMessageRequest;
use App\Models\User;
use App\Services\TechnicalSupportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TechnicalSupportController extends Controller
{
    public function show(Request $request, TechnicalSupportService $support): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذه الخدمة متاحة للطلاب فقط.');
        }

        $ticket = $support->openTicketForStudent($user);

        return $this->successResponse($support->formatTicketForStudent($user, $ticket));
    }

    public function sendMessage(
        SendSupportMessageRequest $request,
        TechnicalSupportService $support,
    ): JsonResponse {
        /** @var User $user */
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذه الخدمة متاحة للطلاب فقط.');
        }

        $result = $support->sendStudentMessage(
            $user,
            (string) $request->validated('message'),
        );

        return $this->successResponse(
            $support->formatTicketForStudent($user, $result['ticket']),
            'تم إرسال رسالتك.',
        );
    }
}
