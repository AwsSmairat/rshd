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
use App\Services\PlatformSettingsService;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Log;
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
        \Illuminate\Http\Resources\Json\JsonResource::withoutWrapping();

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

        $settings = app(PlatformSettingsService::class);
        if (\Illuminate\Support\Facades\Schema::hasTable('platform_settings')) {
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
        ] as $directory) {
            if (! is_dir($directory)) {
                mkdir($directory, 0755, true);
            }
        }

        $this->assertProductionVideoSecurity();
        \App\Services\Bunny\BunnyStreamConfigValidator::warnIfMisconfigured();
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
