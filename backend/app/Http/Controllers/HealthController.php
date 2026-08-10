<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Safe staging/production health probe — no secrets, paths, or env dumps.
 */
class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        $checks = [
            'database' => $this->databaseCheck(),
            'cache' => $this->cacheCheck(),
            'queue' => $this->queueCheck(),
        ];

        $healthy = collect($checks)->every(
            fn (array $check): bool => $check['status'] === 'ok'
        );

        return response()->json([
            'status' => $healthy ? 'ok' : 'degraded',
            'environment' => (string) config('app.env'),
            'checks' => $checks,
        ], $healthy ? 200 : 503);
    }

    /**
     * @return array{status: string, detail: string}
     */
    protected function databaseCheck(): array
    {
        try {
            DB::connection()->getPdo();

            if (! Schema::hasTable('users')) {
                return ['status' => 'fail', 'detail' => 'schema_incomplete'];
            }

            return ['status' => 'ok', 'detail' => 'connected'];
        } catch (\Throwable) {
            return ['status' => 'fail', 'detail' => 'unavailable'];
        }
    }

    /**
     * @return array{status: string, detail: string}
     */
    protected function cacheCheck(): array
    {
        try {
            $key = 'health:probe:'.bin2hex(random_bytes(8));
            Cache::put($key, '1', 10);
            $ok = Cache::get($key) === '1';
            Cache::forget($key);

            return [
                'status' => $ok ? 'ok' : 'fail',
                'detail' => $ok ? 'read_write' : 'read_write_failed',
            ];
        } catch (\Throwable) {
            return ['status' => 'fail', 'detail' => 'unavailable'];
        }
    }

    /**
     * @return array{status: string, detail: string}
     */
    protected function queueCheck(): array
    {
        $driver = (string) config('queue.default');

        if ($driver === 'sync') {
            return ['status' => 'fail', 'detail' => 'sync_not_for_staging'];
        }

        return ['status' => 'ok', 'detail' => 'driver_configured'];
    }
}
