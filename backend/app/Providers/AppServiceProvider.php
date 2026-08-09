<?php

namespace App\Providers;

use App\Models\Assignment;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\LessonFile;
use App\Models\Quiz;
use App\Models\Subject;
use App\Models\User;
use App\Models\Video;
use App\Policies\AssignmentPolicy;
use App\Policies\GradePolicy;
use App\Policies\LessonFilePolicy;
use App\Policies\LessonPolicy;
use App\Policies\QuizPolicy;
use App\Policies\SubjectPolicy;
use App\Policies\UserPolicy;
use App\Policies\VideoPolicy;
use App\Services\Bunny\BunnyStreamConfigValidator;
use App\Services\PlatformSettingsService;
use App\Support\RateLimitKeys;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        JsonResource::withoutWrapping();

        if (request()->is('api/*')) {
            ini_set('display_errors', '0');
            error_reporting(E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED);
        }

        Gate::policy(Subject::class, SubjectPolicy::class);
        Gate::policy(Lesson::class, LessonPolicy::class);
        Gate::policy(Video::class, VideoPolicy::class);
        Gate::policy(LessonFile::class, LessonFilePolicy::class);
        Gate::policy(Assignment::class, AssignmentPolicy::class);
        Gate::policy(Quiz::class, QuizPolicy::class);
        Gate::policy(Grade::class, GradePolicy::class);
        Gate::policy(User::class, UserPolicy::class);

        RateLimiter::for('register', function (Request $request) {
            return [
                Limit::perMinute(10)->by($request->ip()),
                Limit::perHour(30)->by($request->ip()),
            ];
        });

        RateLimiter::for('api-guest', function (Request $request) {
            return Limit::perMinute(60)->by($request->ip());
        });

        RateLimiter::for('api-authenticated', function (Request $request) {
            return [
                Limit::perMinute(180)->by(RateLimitKeys::forRequest($request)),
                Limit::perHour(3000)->by(RateLimitKeys::forRequest($request)),
            ];
        });

        RateLimiter::for('auth-login', function (Request $request) {
            $email = strtolower((string) $request->input('email', ''));

            return [
                Limit::perMinute(10)->by($request->ip()),
                Limit::perMinute(5)->by($request->ip().'|'.$email),
            ];
        });

        RateLimiter::for('auth-password-reset', function (Request $request) {
            $email = strtolower((string) $request->input('email', ''));

            return [
                Limit::perMinute(5)->by($request->ip()),
                Limit::perHour(15)->by($request->ip().'|'.$email),
            ];
        });

        RateLimiter::for('auth-password-forgot', function (Request $request) {
            $email = strtolower((string) $request->input('email', ''));

            return [
                Limit::perMinute(5)->by($request->ip()),
                Limit::perHour(15)->by($request->ip().'|'.$email),
            ];
        });

        RateLimiter::for('auth-password-verify', function (Request $request) {
            $email = strtolower((string) $request->input('email', ''));

            return [
                Limit::perMinute(30)->by($request->ip()),
                Limit::perHour(60)->by($request->ip().'|'.$email),
            ];
        });

        RateLimiter::for('auth-password-resend', function (Request $request) {
            $email = strtolower((string) $request->input('email', ''));

            return [
                Limit::perMinute(5)->by($request->ip()),
                Limit::perHour(15)->by($request->ip().'|'.$email),
            ];
        });

        RateLimiter::for('auth-email-verify', function (Request $request) {
            return [
                Limit::perMinute(10)->by($request->ip()),
                Limit::perHour(30)->by($request->ip()),
            ];
        });

        RateLimiter::for('signed-video', function (Request $request) {
            return Limit::perMinute(45)->by(RateLimitKeys::forRequest($request));
        });

        RateLimiter::for('signed-file', function (Request $request) {
            return Limit::perMinute(45)->by(RateLimitKeys::forRequest($request));
        });

        RateLimiter::for('video-progress', function (Request $request) {
            return Limit::perMinute(120)->by(RateLimitKeys::forRequest($request));
        });

        RateLimiter::for('annotations', function (Request $request) {
            return Limit::perMinute(30)->by(RateLimitKeys::forRequest($request));
        });

        RateLimiter::for('assignment-upload', function (Request $request) {
            return Limit::perMinute(10)->by(RateLimitKeys::forRequest($request));
        });

        RateLimiter::for('notifications-mutations', function (Request $request) {
            return Limit::perMinute(60)->by(RateLimitKeys::forRequest($request));
        });

        RateLimiter::for('webhooks', function (Request $request) {
            return Limit::perMinute(120)->by($request->ip());
        });

        $settings = app(PlatformSettingsService::class);
        if (Schema::hasTable('platform_settings')) {
            $settings->applyMailPreferences();
            $settings->applySecurityPreferences();
        } elseif (app()->environment('local', 'testing')) {
            // During first install or empty local DB, env defaults apply.
        }

        foreach ([
            storage_path('app/public/livewire-tmp'),
            storage_path('app/public/lesson-videos'),
            storage_path('app/public/lesson-files'),
            storage_path('app/private/livewire-tmp'),
            storage_path('app/private/lesson-videos'),
            storage_path('app/private/lesson-files'),
        ] as $directory) {
            if (! is_dir($directory)) {
                mkdir($directory, 0755, true);
            }
        }

        $this->assertProductionVideoSecurity();
        $this->assertProductionFileSecurity();
        BunnyStreamConfigValidator::warnIfMisconfigured();
    }

    protected function assertProductionFileSecurity(): void
    {
        if (! app()->environment('production')) {
            return;
        }

        if (! config('files.signed_download', true)) {
            Log::critical('FILES_SIGNED_DOWNLOAD must be true in production.');
        }

        if (config('files.local_disk') === 'public') {
            Log::critical('FILES_LOCAL_DISK must not be public in production.');
        }
    }

    protected function assertProductionVideoSecurity(): void
    {
        if (! app()->environment('production')) {
            return;
        }

        if (! config('video.signed_playback', true)) {
            Log::critical('VIDEO_SIGNED_PLAYBACK must be true in production.');

            if (! app()->runningInConsole()) {
                abort(503, 'Video playback is misconfigured.');
            }
        }

        if (config('video.local.disk') === 'public') {
            Log::critical('VIDEO_LOCAL_DISK must not be public in production.');
        }

        if (config('video.provider') === 'bunny') {
            $bunnyReady = filled(config('video.bunny.library_id'))
                && filled(config('video.bunny.api_key'));

            if (config('video.bunny.playback_mode', 'embed') === 'cdn') {
                $bunnyReady = $bunnyReady
                    && filled(config('video.bunny.token_key'))
                    && filled(config('video.bunny.cdn_hostname'));
            }

            if (! $bunnyReady) {
                Log::critical('VIDEO_PROVIDER=bunny but Bunny Stream credentials are incomplete.');
            }
        }
    }
}
