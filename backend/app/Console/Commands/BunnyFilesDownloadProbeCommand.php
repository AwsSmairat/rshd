<?php

namespace App\Console\Commands;

use App\Models\LessonFile;
use App\Services\Bunny\BunnyFilesCdnTokenSigner;
use App\Services\LessonFileDownloadService;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class BunnyFilesDownloadProbeCommand extends Command
{
    protected $signature = 'files:bunny-download-probe {file : Lesson file id} {--user-id= : User id for signed URL generation}';

    protected $description = 'Probe signed/unsigned Bunny CDN access for a lesson file (no secrets printed)';

    public function handle(
        LessonFileDownloadService $downloadService,
        BunnyFilesCdnTokenSigner $signer,
    ): int {
        $lessonFile = LessonFile::query()->find($this->argument('file'));

        if ($lessonFile === null) {
            $this->error('Lesson file not found.');

            return self::FAILURE;
        }

        if (! $lessonFile->isBunnyStored()) {
            $this->error('Lesson file is not stored on Bunny.');

            return self::FAILURE;
        }

        $userId = $this->option('user-id');
        $user = $userId ? User::query()->find($userId) : User::query()->where('role', 'admin')->first();

        if ($user === null) {
            $this->error('No user available to generate signed URL.');

            return self::FAILURE;
        }

        $download = $downloadService->generateDownloadUrl($lessonFile, $user);

        if ($download === null) {
            $this->error('Could not generate signed download URL.');

            return self::FAILURE;
        }

        $unsigned = $signer->unsignedCdnUrl((string) $lessonFile->external_path);

        $signedStatus = $this->probe($download['url']);
        $unsignedStatus = $this->probe($unsigned);

        $this->line('Pilot file ID: '.$lessonFile->id);
        $this->line('Signed PDF HTTP: '.$signedStatus);
        $this->line('Unsigned PDF HTTP: '.$unsignedStatus);
        $this->line('External path saved: '.($lessonFile->external_path ? 'yes' : 'no'));

        return $signedStatus === '200' && $unsignedStatus === '403'
            ? self::SUCCESS
            : self::FAILURE;
    }

    protected function probe(string $url): string
    {
        try {
            $response = Http::timeout(20)->withOptions(['allow_redirects' => true])->get($url);

            return (string) $response->status();
        } catch (\Throwable) {
            return 'error';
        }
    }
}
