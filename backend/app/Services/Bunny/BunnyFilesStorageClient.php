<?php

namespace App\Services\Bunny;

use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class BunnyFilesStorageClient
{
    /**
     * Known Bunny Edge Storage regional hostnames (storage API, not CDN).
     *
     * @var list<string>
     */
    public const REGIONAL_HOSTNAMES = [
        'storage.bunnycdn.com',
        'uk.storage.bunnycdn.com',
        'ny.storage.bunnycdn.com',
        'la.storage.bunnycdn.com',
        'sg.storage.bunnycdn.com',
        'se.storage.bunnycdn.com',
        'br.storage.bunnycdn.com',
        'jh.storage.bunnycdn.com',
        'syd.storage.bunnycdn.com',
    ];

    public function isConfigured(): bool
    {
        return filled(config('files.bunny.storage_zone'))
            && filled(config('files.bunny.storage_password'));
    }

    public function storageHostname(): string
    {
        $hostname = trim((string) config('files.bunny.storage_hostname'));

        return $hostname !== '' ? $hostname : 'storage.bunnycdn.com';
    }

    /**
     * @return array{
     *     ok: bool,
     *     http_status: int|null,
     *     storage_hostname: string|null,
     *     root_objects_count: int|null,
     *     failure_category: string|null,
     *     response: Response|null,
     * }
     */
    public function probeRootListing(): array
    {
        $zone = (string) config('files.bunny.storage_zone');
        $password = (string) config('files.bunny.storage_password');
        $configuredHostname = trim((string) config('files.bunny.storage_hostname'));

        if ($zone === '' || $password === '') {
            return [
                'ok' => false,
                'http_status' => null,
                'storage_hostname' => null,
                'root_objects_count' => null,
                'failure_category' => 'configuration',
                'response' => null,
            ];
        }

        $hostnames = $configuredHostname !== ''
            ? [$configuredHostname]
            : self::REGIONAL_HOSTNAMES;

        $lastResponse = null;
        $lastHostname = null;

        foreach ($hostnames as $hostname) {
            $lastHostname = $hostname;
            $response = $this->listDirectoryRequest($hostname, $zone, $password, '');
            $lastResponse = $response;

            if ($response->successful()) {
                $items = $response->json();

                return [
                    'ok' => true,
                    'http_status' => $response->status(),
                    'storage_hostname' => $hostname,
                    'root_objects_count' => is_array($items) ? count($items) : 0,
                    'failure_category' => null,
                    'response' => $response,
                ];
            }

            if ($response->status() === 401) {
                return [
                    'ok' => false,
                    'http_status' => 401,
                    'storage_hostname' => $hostname,
                    'root_objects_count' => null,
                    'failure_category' => 'password',
                    'response' => $response,
                ];
            }
        }

        return [
            'ok' => false,
            'http_status' => $lastResponse?->status(),
            'storage_hostname' => $lastHostname,
            'root_objects_count' => null,
            'failure_category' => $this->categorizeFailure($lastResponse),
            'response' => $lastResponse,
        ];
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function listDirectory(string $path = ''): array
    {
        $response = $this->listDirectoryRequest(
            $this->storageHostname(),
            (string) config('files.bunny.storage_zone'),
            (string) config('files.bunny.storage_password'),
            $path,
        );

        if (! $response->successful()) {
            throw new RuntimeException('Failed to list Bunny Storage directory.');
        }

        $items = $response->json();

        return is_array($items) ? $items : [];
    }

    public function upload(string $remotePath, string $contents, string $contentType = 'application/pdf'): bool
    {
        $response = $this->objectRequest('PUT', $remotePath, $contents, $contentType);

        return in_array($response->status(), [201, 200], true);
    }

    public function exists(string $remotePath): bool
    {
        $response = $this->objectRequest('HEAD', $remotePath);

        if ($response->status() === 200) {
            return true;
        }

        $parent = trim(str_replace('\\', '/', dirname($remotePath)), '/.');
        $fileName = basename($remotePath);

        if ($fileName === '' || $fileName === '.') {
            return false;
        }

        try {
            $items = $this->listDirectory($parent === '' ? '' : $parent);

            foreach ($items as $item) {
                if (($item['ObjectName'] ?? null) === $fileName) {
                    return true;
                }
            }
        } catch (\Throwable) {
            return false;
        }

        return false;
    }

    /**
     * Internal cleanup helper — not used in pilot flow.
     */
    public function delete(string $remotePath): bool
    {
        $response = $this->objectRequest('DELETE', $remotePath);

        return in_array($response->status(), [200, 204, 404], true);
    }

    protected function objectRequest(
        string $method,
        string $remotePath,
        ?string $body = null,
        ?string $contentType = null,
    ): Response {
        if (! $this->isConfigured()) {
            throw new RuntimeException('Bunny Files storage is not configured.');
        }

        $url = $this->buildObjectUrl(
            $this->storageHostname(),
            (string) config('files.bunny.storage_zone'),
            $remotePath,
        );

        $headers = [
            'AccessKey' => (string) config('files.bunny.storage_password'),
        ];

        if ($contentType !== null) {
            $headers['Content-Type'] = $contentType;
        }

        $pending = Http::timeout(120)->withHeaders($headers);

        return match (strtoupper($method)) {
            'PUT' => $pending->withBody($body ?? '', $contentType ?? 'application/octet-stream')->put($url),
            'HEAD' => $pending->head($url),
            'DELETE' => $pending->delete($url),
            default => throw new RuntimeException("Unsupported Bunny Storage method: {$method}"),
        };
    }

    protected function listDirectoryRequest(
        string $hostname,
        string $zone,
        string $password,
        string $path,
    ): Response {
        return Http::timeout(20)
            ->withHeaders(['AccessKey' => $password])
            ->get($this->buildListUrl($hostname, $zone, $path));
    }

    public function buildListUrl(string $hostname, string $zone, string $path = ''): string
    {
        $hostname = $this->normalizeHostname($hostname);
        $path = trim($path, '/');

        if ($path === '') {
            return "{$hostname}/{$zone}/";
        }

        return "{$hostname}/{$zone}/{$path}/";
    }

    public function buildObjectUrl(string $hostname, string $zone, string $remotePath): string
    {
        $hostname = $this->normalizeHostname($hostname);
        $remotePath = ltrim($remotePath, '/');

        return "{$hostname}/{$zone}/{$remotePath}";
    }

    protected function normalizeHostname(string $hostname): string
    {
        $hostname = trim($hostname);
        if (! str_starts_with($hostname, 'http://') && ! str_starts_with($hostname, 'https://')) {
            $hostname = 'https://'.$hostname;
        }

        return rtrim($hostname, '/');
    }

    protected function categorizeFailure(?Response $response): string
    {
        if ($response === null) {
            return 'network';
        }

        if ($response->status() === 401) {
            return 'password';
        }

        if ($response->connectionFailed()) {
            return 'network';
        }

        return 'endpoint';
    }
}
