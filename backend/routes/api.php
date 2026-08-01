<?php

use App\Http\Controllers\Api\V1\HelpCenterController;
use App\Http\Controllers\Api\V1\StudentSettingsController;
use App\Http\Controllers\Api\V1\StudentTermsController;
use App\Http\Controllers\Api\V1\PublicSettingsController;
use App\Http\Controllers\Api\V1\AnnouncementController;
use App\Http\Controllers\Api\V1\AssignmentController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\EmailVerificationController;
use App\Http\Controllers\Api\V1\GradeController;
use App\Http\Controllers\Api\V1\LessonController;
use App\Http\Controllers\Api\V1\LessonFileController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\QuizController;
use App\Http\Controllers\Api\V1\SubjectController;
use App\Http\Controllers\Api\V1\VideoController;
use App\Models\LessonFile;
use Illuminate\Support\Facades\Route;

Route::bind('file', fn (string $value) => LessonFile::findOrFail($value));

Route::prefix('v1')->group(function () {
    Route::get('settings/public', PublicSettingsController::class);

    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('auth/google', [AuthController::class, 'googleAuth']);
    Route::post('auth/apple', [AuthController::class, 'appleAuth']);
    Route::post('email/verify', [EmailVerificationController::class, 'verify']);
    Route::post('email/resend', [EmailVerificationController::class, 'resend']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('me', [AuthController::class, 'me']);

        Route::get('my-subjects', [SubjectController::class, 'mySubjects']);
        Route::get('subjects', [SubjectController::class, 'catalog']);
        Route::post('subjects/{subject}/purchase-request', [SubjectController::class, 'purchaseRequest']);

        Route::get('subjects/{subject}/lessons', [LessonController::class, 'index']);
        Route::get('lessons/{lesson}', [LessonController::class, 'show']);

        Route::get('videos/{video}', [VideoController::class, 'show']);
        Route::post('videos/{video}/progress', [VideoController::class, 'updateProgress']);

        Route::get('files/{file}', [LessonFileController::class, 'show']);
        Route::get('files/{file}/annotations', [LessonFileController::class, 'getAnnotations']);
        Route::post('files/{file}/annotations', [LessonFileController::class, 'storeAnnotations']);

        Route::get('assignments', [AssignmentController::class, 'index']);
        Route::post('assignments/{assignment}/submit', [AssignmentController::class, 'submit']);

        Route::get('quizzes', [QuizController::class, 'index']);
        Route::post('quizzes/{quiz}/start', [QuizController::class, 'start']);
        Route::post('quizzes/{quiz}/submit', [QuizController::class, 'submit']);

        Route::get('grades', [GradeController::class, 'index']);

        Route::get('announcements', [AnnouncementController::class, 'index']);

        Route::get('notifications', [NotificationController::class, 'index']);
        Route::post('notifications/{notification}/read', [NotificationController::class, 'markAsRead']);

        Route::prefix('student')->group(function () {
            Route::get('help/contacts', [HelpCenterController::class, 'contacts']);
            Route::post('help/messages', [HelpCenterController::class, 'sendMessage']);
            Route::get('settings', [StudentSettingsController::class, 'show']);
            Route::patch('profile', [StudentSettingsController::class, 'updateProfile']);
            Route::post('avatar', [StudentSettingsController::class, 'uploadAvatar']);
            Route::delete('avatar', [StudentSettingsController::class, 'deleteAvatar']);
            Route::patch('password', [StudentSettingsController::class, 'updatePassword']);
            Route::patch('preferences', [StudentSettingsController::class, 'updatePreferences']);
            Route::delete('devices/{device}', [StudentSettingsController::class, 'revokeDevice']);
            Route::post('logout-all-devices', [StudentSettingsController::class, 'logoutAllDevices']);
            Route::post('account/delete', [StudentSettingsController::class, 'deleteAccount']);
            Route::get('terms/status', [StudentTermsController::class, 'status']);
            Route::post('terms/accept', [StudentTermsController::class, 'accept']);
        });
    });
});
