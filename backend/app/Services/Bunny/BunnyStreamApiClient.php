<?php

namespace App\Services\Bunny;

use Illuminate\Http\Client\PendingRequest;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class BunnyStreamApiClient
{
    protected string $baseUrl = 'https://video.bunnycdn.com';

    public function isConfigured(): bool
    {
        return filled(config('video.bunny.library_id'))
            && filled(config('video.bunny.api_key'));
    }

    /**
     * @return array<string, mixed>
     */
    public function createVideo(string $title): array
    {
        $response = $this->request()
            ->post("/library/{$this->libraryId()}/videos", [
                'title' => $title,
            ]);

        if (! $response->successful()) {
            $this->logApiFailure('create_video', $response->status(), $response->json());

            throw new RuntimeException('Failed to create Bunny Stream video.');
        }

        /** @var array<string, mixed> $payload */
        $payload = $response->json();

        return $payload;
    }

    /**
     * @param  resource|string  $body
     */
    public function uploadVideo(string $videoGuid, mixed $body): void
    {
        $response = Http::withHeaders([
            'AccessKey' => $this->apiKey(),
        ])
            ->withBody($body, 'application/octet-stream')
            ->timeout(max(120, (int) config('video.bunny.upload_timeout', 3600)))
            ->put("{$this->baseUrl}/library/{$this->libraryId()}/videos/{$videoGuid}");

        if (! $response->successful()) {
            $this->logApiFailure('upload_video', $response->status(), $response->json(), $videoGuid);

            throw new RuntimeException('Failed to upload video to Bunny Stream.');
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function getVideo(string $videoGuid): array
    {
        $response = $this->request()
            ->get("/library/{$this->libraryId()}/videos/{$videoGuid}");

        if ($response->status() === 404) {
            throw new RuntimeException('Bunny Stream video was not found.');
        }

        if (! $response->successful()) {
            $this->logApiFailure('get_video', $response->status(), $response->json(), $videoGuid);

            throw new RuntimeException('Failed to fetch Bunny Stream video.');
        }

        /** @var array<string, mixed> $payload */
        $payload = $response->json();

        return $payload;
    }

    protected function request(): PendingRequest
    {
        if (! $this->isConfigured()) {
            throw new RuntimeException('Bunny Stream API credentials are not configured.');
        }

        return Http::withHeaders([
            'AccessKey' => $this->apiKey(),
            'Accept' => 'application/json',
        ])
            ->baseUrl($this->baseUrl)
            ->retry(
                times: 3,
                sleepMilliseconds: fn (int $attempt, RequestException $exception) => $attempt * 1000,
                when: fn ($exception) => $exception instanceof RequestException
                    && in_array($exception->response?->status(), [429, 500, 502, 503, 504], true),
            );
    }

    protected function libraryId(): string
    {
        return (string) config('video.bunny.library_id');
    }

    protected function apiKey(): string
    {
        return (string) config('video.bunny.api_key');
    }

    /**
     * @param  array<string, mixed>|null  $payload
     */
    protected function logApiFailure(string $event, int $status, ?array $payload, ?string $videoGuid = null): void
    {
        Log::warning('bunny.stream.api.failed', [
            'event' => $event,
            'status' => $status,
            'external_video_id' => $videoGuid,
            'message' => is_array($payload) ? ($payload['message'] ?? null) : null,
        ]);
    }
}
