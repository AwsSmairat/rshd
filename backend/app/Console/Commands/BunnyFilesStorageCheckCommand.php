<?php

namespace App\Console\Commands;

use App\Services\Bunny\BunnyFilesStorageClient;
use Illuminate\Console\Command;

class BunnyFilesStorageCheckCommand extends Command
{
    protected $signature = 'bunny:files-storage-check';

    protected $description = 'Read-only Bunny Edge Storage connection check for lesson files/PDFs (no secrets printed)';

    public function handle(BunnyFilesStorageClient $client): int
    {
        $checks = [
            'BUNNY_FILES_TOKEN_KEY' => filled(config('files.bunny.token_key')),
            'BUNNY_FILES_CDN_HOSTNAME' => filled(config('files.bunny.cdn_hostname')),
            'BUNNY_FILES_STORAGE_ZONE' => filled(config('files.bunny.storage_zone')),
            'BUNNY_FILES_STORAGE_PASSWORD' => filled(config('files.bunny.storage_password')),
        ];

        foreach ($checks as $name => $configured) {
            $this->line($name.': configured '.($configured ? '✅' : '❌'));
        }

        if (! $client->isConfigured()) {
            $this->newLine();
            $this->line('Storage API connection: FAIL');
            $this->line('HTTP status: n/a');
            $this->line('Storage zone reachable: no');
            $this->line('Root objects count: n/a');
            $this->line('Failure category: configuration');

            return self::FAILURE;
        }

        $result = $client->probeRootListing();

        $this->newLine();
        $this->line('Storage API connection: '.($result['ok'] ? 'PASS' : 'FAIL'));
        $this->line('HTTP status: '.($result['http_status'] ?? 'n/a'));
        $this->line('Storage zone reachable: '.($result['ok'] ? 'yes' : 'no'));
        $this->line('Root objects count: '.($result['root_objects_count'] ?? 'n/a'));

        if ($result['storage_hostname'] !== null) {
            $this->line('Storage hostname used: '.$result['storage_hostname']);
        }

        if (! filled(config('files.bunny.storage_hostname')) && $result['ok']) {
            $this->line('Note: set BUNNY_FILES_STORAGE_HOSTNAME='.$result['storage_hostname'].' in .env to skip region probing.');
        }

        if (! $result['ok'] && $result['failure_category'] !== null) {
            $this->line('Failure category: '.$result['failure_category']);
        }

        return $result['ok'] ? self::SUCCESS : self::FAILURE;
    }
}
