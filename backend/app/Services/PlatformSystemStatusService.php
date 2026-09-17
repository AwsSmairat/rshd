<?php

namespace App\Services;

use App\Services\Bunny\BunnyStreamService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

class PlatformSystemStatusService
{
    /**
     * @return list<array{label: string, status: string, tone: string}>
     */
    public function rows(): array
    {
        return [
            $this->databaseRow(),
            $this->mailRow(),
            $this->storageRow(),
            $this->videoRow(),
            $this->queueRow(),
            $this->schedulerRow(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function environment(): array
    {
        return [
            'app_debug' => (bool) config('app.debug'),
            'https' => request()->isSecure(),
            'environment' => (string) config('app.env'),
            'laravel_version' => app()->version(),
            'php_version' => PHP_VERSION,
        ];
    }

    public function mailConfigured(): bool
    {
        $mailer = (string) config('mail.default');

        if ($mailer === 'log' || $mailer === 'array') {
            return app()->environment('local');
        }

        if ($mailer === 'smtp') {
            return filled(config('mail.mailers.smtp.host'))
                && filled(config('mail.mailers.smtp.username'));
        }

        return filled($mailer);
    }

    /**
     * @return array{label: string, status: string, tone: string}
     */
    protected function databaseRow(): array
    {
        try {
            DB::connection()->getPdo();
            $connected = Schema::hasTable('users');
        } catch (\Throwable) {
            $connected = false;
        }

        return [
            'label' => 'قاعدة البيانات',
            'status' => $connected ? 'متصل' : 'غير مهيأ',
            'tone' => $connected ? 'success' : 'danger',
        ];
    }

    /**
     * @return array{label: string, status: string, tone: string}
     */
    protected function mailRow(): array
    {
        $configured = $this->mailConfigured();

        return [
            'label' => 'خدمة البريد الإلكتروني',
            'status' => $configured ? 'متصل' : 'غير مهيأ',
            'tone' => $configured ? 'success' : 'warning',
        ];
    }

    /**
     * @return array{label: string, status: string, tone: string}
     */
    protected function storageRow(): array
    {
        try {
            Storage::disk('public')->put('_healthcheck.txt', 'ok');
            $ok = Storage::disk('public')->exists('_healthcheck.txt');
            Storage::disk('public')->delete('_healthcheck.txt');
        } catch (\Throwable) {
            $ok = false;
        }

        return [
            'label' => 'تخزين الملفات',
            'status' => $ok ? 'متصل' : 'غير مهيأ',
            'tone' => $ok ? 'success' : 'danger',
        ];
    }

    /**
     * @return array{label: string, status: string, tone: string}
     */
    protected function videoRow(): array
    {
        $provider = (string) config('video.provider', 'local');

        if ($provider === 'bunny') {
            $connected = app(BunnyStreamService::class)->isConfigured();
        } else {
            try {
                $disk = Storage::disk((string) config('video.local.disk', 'lesson_videos'));
                $healthcheck = '_video_healthcheck.txt';

                $disk->put($healthcheck, 'ok');
                $connected = $disk->exists($healthcheck);
                $disk->delete($healthcheck);
            } catch (\Throwable) {
                $connected = false;
            }
        }

        return [
            'label' => 'خدمة الفيديو',
            'status' => $connected ? 'متصل' : 'غير مهيأ',
            'tone' => $connected ? 'success' : 'warning',
        ];
    }

    /**
     * @return array{label: string, status: string, tone: string}
     */
    protected function queueRow(): array
    {
        $driver = (string) config('queue.default');

        if ($driver === 'sync') {
            $running = true;
        } else {
            $lastRun = cache('queue_worker_last_run');
            $running = $lastRun && now()->diffInMinutes($lastRun) <= 5;
        }

        return [
            'label' => 'Queue worker',
            'status' => $running ? 'متصل' : 'متوقف',
            'tone' => $running ? 'success' : 'warning',
        ];
    }

    /**
     * @return array{label: string, status: string, tone: string}
     */
    protected function schedulerRow(): array
    {
        $lastRun = cache('scheduler_last_run');
        $recent = $lastRun && now()->diffInMinutes($lastRun) <= 5;

        return [
            'label' => 'Scheduler',
            'status' => $recent ? 'متصل' : 'متوقف',
            'tone' => $recent ? 'success' : 'warning',
        ];
    }
}
