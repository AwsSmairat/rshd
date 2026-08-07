<?php

namespace App\Services\Bunny;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class BunnyStreamWebhookService
{
    public function __construct(
        protected BunnyStreamService $bunnyStream,
    ) {}

    public function validateSignature(Request $request, string $rawBody): bool
    {
        $secret = (string) config('video.bunny.read_only_api_key');

        if ($secret === '') {
            Log::critical('bunny.stream.webhook.secret_missing');

            return false;
        }

        $version = (string) $request->header('X-BunnyStream-Signature-Version', '');
        $algorithm = (string) $request->header('X-BunnyStream-Signature-Algorithm', '');
        $signature = (string) $request->header('X-BunnyStream-Signature', '');

        if ($version !== 'v1' || $algorithm !== 'hmac-sha256') {
            return false;
        }

        $expected = hash_hmac('sha256', $rawBody, $secret);

        if ($signature === '' || strlen($signature) !== strlen($expected)) {
            return false;
        }

        return hash_equals($expected, $signature);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function handle(array $payload): void
    {
        $this->bunnyStream->applyWebhookPayload($payload);
    }
}
