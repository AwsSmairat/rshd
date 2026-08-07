<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Bunny\BunnyStreamWebhookService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BunnyStreamWebhookController extends Controller
{
    public function __invoke(Request $request, BunnyStreamWebhookService $webhooks): JsonResponse
    {
        $rawBody = $request->getContent();

        if (! $webhooks->validateSignature($request, $rawBody)) {
            return response()->json(['success' => false], 401);
        }

        /** @var array<string, mixed> $payload */
        $payload = json_decode($rawBody, true) ?? [];

        $webhooks->handle($payload);

        return response()->json(['success' => true]);
    }
}
