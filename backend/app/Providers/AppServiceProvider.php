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
        $settings->applyMailPreferences();
        $settings->applySecurityPreferences();

        foreach ([
            storage_path('app/public/livewire-tmp'),
            storage_path('app/public/lesson-videos'),
            storage_path('app/public/lesson-files'),
            storage_path('app/private/livewire-tmp'),
        ] as $directory) {
            if (! is_dir($directory)) {
                mkdir($directory, 0755, true);
            }
        }
    }
}
