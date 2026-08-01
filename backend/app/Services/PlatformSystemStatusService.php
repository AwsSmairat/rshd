<?php

namespace App\Services;

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
        $hasFfprobe = app(VideoMetadataService::class)->isAvailable();

        return [
            'label' => 'خدمة الفيديو',
            'status' => $hasFfprobe ? 'متصل' : 'غير مهيأ',
            'tone' => $hasFfprobe ? 'success' : 'warning',
        ];
    }

    /**
     * @return array{label: string, status: string, tone: string}
     */
    protected function queueRow(): array
    {
        $driver = (string) config('queue.default');
        $running = $driver === 'sync' || $driver === 'database';

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
