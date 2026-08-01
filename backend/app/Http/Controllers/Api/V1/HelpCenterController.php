<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\SendStudentHelpMessageRequest;
use App\Models\User;
use App\Services\HelpCenterService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HelpCenterController extends Controller
{
    public function contacts(Request $request, HelpCenterService $helpCenter): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذه الخدمة متاحة للطلاب فقط.');
        }

        return $this->successResponse($helpCenter->contactsForStudent($user));
    }

    public function sendMessage(
        SendStudentHelpMessageRequest $request,
        HelpCenterService $helpCenter,
    ): JsonResponse {
        /** @var User $user */
        $user = $request->user();

        if (! $user->isStudent()) {
            return $this->forbiddenResponse('هذه الخدمة متاحة للطلاب فقط.');
        }

        $notification = $helpCenter->sendMessageToInstructor(
            $user,
            (int) $request->validated('subject_id'),
            (string) $request->validated('message'),
        );

        return $this->successResponse([
            'id' => $notification->id,
            'sent_at' => $notification->created_at?->toIso8601String(),
        ], 'تم إرسال رسالتك إلى المدرّس.');
    }
}
