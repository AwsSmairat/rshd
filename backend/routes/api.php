<?php

use App\Http\Controllers\Api\BunnyStreamWebhookController;
use App\Http\Controllers\Api\V1\AnnouncementController;
use App\Http\Controllers\Api\V1\AssignmentController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\EmailVerificationController;
use App\Http\Controllers\Api\V1\GradeController;
use App\Http\Controllers\Api\V1\HelpCenterController;
use App\Http\Controllers\Api\V1\LegalDocumentController;
use App\Http\Controllers\Api\V1\LessonController;
use App\Http\Controllers\Api\V1\LessonFileController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\PasswordResetController;
use App\Http\Controllers\Api\V1\PublicSettingsController;
use App\Http\Controllers\Api\V1\QuizController;
use App\Http\Controllers\Api\V1\StudentSettingsController;
use App\Http\Controllers\Api\V1\StudentTermsController;
use App\Http\Controllers\Api\V1\SubjectController;
use App\Http\Controllers\Api\V1\TechnicalSupportController;
use App\Http\Controllers\Api\V1\VideoController;
use App\Http\Controllers\Api\V1\VideoStreamController;
use App\Models\LessonFile;
use Illuminate\Support\Facades\Route;

Route::bind('file', fn (string $value) => LessonFile::findOrFail($value));

Route::prefix('v1')->middleware('throttle:api-guest')->group(function () {
    Route::get('settings/public', PublicSettingsController::class);
    Route::get('legal/privacy-policy', [LegalDocumentController::class, 'privacyPolicy']);
    Route::get('legal/terms', [LegalDocumentController::class, 'terms']);

    Route::post('register', [AuthController::class, 'register'])->middleware('throttle:register');
    Route::post('login', [AuthController::class, 'login'])->middleware('throttle:auth-login');
    Route::post('auth/google', [AuthController::class, 'googleAuth'])->middleware('throttle:auth-login');
    Route::post('auth/apple', [AuthController::class, 'appleAuth'])->middleware('throttle:auth-login');
    Route::post('email/verify', [EmailVerificationController::class, 'verify'])->middleware('throttle:auth-email-verify');
    Route::post('email/resend', [EmailVerificationController::class, 'resend'])->middleware('throttle:auth-email-verify');
    Route::post('password/forgot', [PasswordResetController::class, 'forgot'])->middleware('throttle:auth-password-forgot');
    Route::post('password/verify', [PasswordResetController::class, 'verify'])->middleware('throttle:auth-password-verify');
    Route::post('password/reset', [PasswordResetController::class, 'reset'])->middleware('throttle:auth-password-reset');
    Route::post('password/resend', [PasswordResetController::class, 'resend'])->middleware('throttle:auth-password-resend');

    Route::get('videos/{video}/stream', [VideoStreamController::class, 'stream'])
        ->name('api.v1.videos.stream');

    Route::get('files/{file}/stream', [LessonFileController::class, 'stream'])
        ->middleware('signed')
        ->name('api.v1.files.stream');
});

Route::post('v1/webhooks/bunny/stream', BunnyStreamWebhookController::class)
    ->middleware('throttle:webhooks')
    ->name('api.webhooks.bunny.stream');

Route::prefix('v1')->middleware(['auth:sanctum', 'throttle:api-authenticated'])->group(function () {
    Route::post('logout', [AuthController::class, 'logout']);

    Route::get('me', [AuthController::class, 'me']);

    Route::get('my-subjects', [SubjectController::class, 'mySubjects']);
    Route::get('subjects', [SubjectController::class, 'catalog']);
    Route::post('subjects/{subject}/purchase-request', [SubjectController::class, 'purchaseRequest']);
    Route::delete('subjects/{subject}/purchase-request', [SubjectController::class, 'cancelPurchaseRequest']);

    Route::get('subjects/{subject}/lessons', [LessonController::class, 'index']);
    Route::get('lessons/{lesson}', [LessonController::class, 'show']);

    Route::get('videos/{video}', [VideoController::class, 'show']);
    Route::get('videos/{video}/playback', [VideoController::class, 'playback'])
        ->middleware('throttle:signed-video');
    Route::post('videos/{video}/progress', [VideoController::class, 'updateProgress'])
        ->middleware('throttle:video-progress');

    Route::get('files/{file}', [LessonFileController::class, 'show']);
    Route::get('files/{file}/download', [LessonFileController::class, 'download'])
        ->middleware('throttle:signed-file');
    Route::get('files/{file}/annotations', [LessonFileController::class, 'getAnnotations']);
    Route::post('files/{file}/annotations', [LessonFileController::class, 'storeAnnotations'])
        ->middleware('throttle:annotations');

    Route::get('assignments', [AssignmentController::class, 'index']);
    Route::post('assignments/{assignment}/submit', [AssignmentController::class, 'submit'])
        ->middleware('throttle:assignment-upload');

    Route::get('quizzes', [QuizController::class, 'index']);
    Route::post('quizzes/{quiz}/start', [QuizController::class, 'start']);
    Route::post('quizzes/{quiz}/submit', [QuizController::class, 'submit']);

    Route::get('grades', [GradeController::class, 'index']);

    Route::get('announcements', [AnnouncementController::class, 'index']);

    Route::get('notifications', [NotificationController::class, 'index']);
    Route::post('notifications/{notification}/read', [NotificationController::class, 'markAsRead'])
        ->middleware('throttle:notifications-mutations');

    Route::prefix('student')->group(function () {
        Route::get('help/contacts', [HelpCenterController::class, 'contacts']);
        Route::post('help/messages', [HelpCenterController::class, 'sendMessage']);
        Route::get('support/ticket', [TechnicalSupportController::class, 'show']);
        Route::post('support/messages', [TechnicalSupportController::class, 'sendMessage']);
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
