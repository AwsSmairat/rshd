<?php

/**
 * Internal smoke test — run: php tests/smoke.php
 * Requires: php artisan serve (or uses direct HTTP if BASE_URL set)
 */

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Assignment;
use App\Models\LessonFile;
use App\Models\User;
use App\Models\Video;
use App\Services\InstructorInvitationService;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\DB;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

$base = getenv('BASE_URL') ?: 'http://127.0.0.1:8770';
$passed = 0;
$failed = 0;

function check(string $label, bool $ok): void
{
    global $passed, $failed;
    if ($ok) {
        echo "✓ $label\n";
        $passed++;
    } else {
        echo "✗ $label\n";
        $failed++;
    }
}

// Assignment submit with multipart file upload
function apiMultipart(string $path, array $fields, ?string $filePath, ?string $token = null): array
{
    global $base;
    $ch = curl_init(rtrim($base, '/').'/api/v1/'.$path);
    $postFields = $fields;
    if ($filePath !== null && file_exists($filePath)) {
        $postFields['file'] = new CURLFile($filePath, 'application/pdf', basename($filePath));
    }
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => array_filter([
            'Accept: application/json',
            $token ? "Authorization: Bearer $token" : null,
        ]),
        CURLOPT_POSTFIELDS => $postFields,
    ]);
    $raw = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode($raw ?: '{}', true) ?? [];

    return ['code' => $code, 'json' => $json, 'raw' => $raw];
}

function api(string $method, string $path, ?array $body = null, ?string $token = null): array
{
    global $base;
    $ch = curl_init(rtrim($base, '/').'/api/v1/'.$path);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => array_filter([
            'Accept: application/json',
            $body ? 'Content-Type: application/json' : null,
            $token ? "Authorization: Bearer $token" : null,
        ]),
        CURLOPT_POSTFIELDS => $body ? json_encode($body) : null,
    ]);
    $raw = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode($raw ?: '{}', true) ?? [];

    return ['code' => $code, 'json' => $json, 'raw' => $raw];
}

echo "=== RSHD Smoke Tests ===\n\n";

// Filament access
$panel = Filament\Facades\Filament::getPanel('admin');
$admin = User::where('email', 'admin@rshdacademy.com')->first();
$instructor = User::where('email', 'instructor@rshdacademy.com')->first();
$student = User::where('email', 'student@rshdacademy.com')->first();

check('Admin can access Filament', $admin->canAccessPanel($panel));
check('Instructor with password can access Filament', $instructor->canAccessPanel($panel));
check('Student blocked from Filament', ! $student->canAccessPanel($panel));

$pending = User::factory()->make(['role' => UserRole::Instructor, 'password_set_at' => null]);
$pending->role = UserRole::Instructor;
$pending->password_set_at = null;
check('Instructor without password_set_at blocked from Filament', ! $pending->canAccessPanel($panel));

// Login
foreach (['admin@rshdacademy.com', 'instructor@rshdacademy.com', 'student@rshdacademy.com'] as $email) {
    $r = api('POST', 'login', ['email' => $email, 'password' => 'password']);
    check("Login $email", $r['code'] === 200 && isset($r['json']['data']['token']));
}

$login = api('POST', 'login', ['email' => 'student@rshdacademy.com', 'password' => 'password']);
$token = $login['json']['data']['token'] ?? null;
check('Student token received', $token !== null);

$endpoints = ['me', 'my-subjects', 'assignments', 'quizzes', 'grades', 'notifications', 'announcements'];
foreach ($endpoints as $ep) {
    $r = api('GET', $ep, null, $token);
    check("GET /$ep", $r['code'] === 200);
}

$r = api('GET', 'subjects/1/lessons', null, $token);
check('GET /subjects/1/lessons', $r['code'] === 200);

$assignment = Assignment::query()->first();
if ($assignment !== null && $token !== null) {
    $tmpPdf = sys_get_temp_dir().'/rshd-smoke-assignment.pdf';
    file_put_contents($tmpPdf, '%PDF-1.4 RSHD smoke test');
    $submit = apiMultipart(
        "assignments/{$assignment->id}/submit",
        ['answer_text' => 'اختبار smoke test'],
        $tmpPdf,
        $token,
    );
    check(
        'POST /assignments/{id}/submit multipart',
        $submit['code'] === 200
        && ! empty($submit['json']['data']['file_url'] ?? null),
    );
    @unlink($tmpPdf);
}

$videoId = Video::first()?->id;
$fileId = LessonFile::first()?->id;

if ($videoId) {
    check('GET /videos/{id}', api('GET', "videos/$videoId", null, $token)['code'] === 200);
    check('POST /videos/{id}/progress', api('POST', "videos/$videoId/progress", ['watched_seconds' => 10, 'current_position' => 10], $token)['code'] === 200);
}

if ($fileId) {
    check('GET /files/{id}', api('GET', "files/$fileId", null, $token)['code'] === 200);
    check('POST /files/{id}/annotations', api('POST', "files/$fileId/annotations", ['annotation_json' => ['page' => 1]], $token)['code'] === 200);
}

// Register requires email verification
$regEmail = 'noenroll'.time().'@test.com';
$reg = api('POST', 'register', [
    'name' => 'No Enroll',
    'email' => $regEmail,
    'password' => 'password',
    'password_confirmation' => 'password',
]);
check(
    'Register returns requires_email_verification',
    $reg['code'] === 201
    && ($reg['json']['data']['requires_email_verification'] ?? false) === true
    && ! isset($reg['json']['data']['token'])
);

$newStudent = User::where('email', $regEmail)->first();
if ($newStudent) {
    $newStudent->update(['email_verified_at' => now()]);
    $newToken = $newStudent->createToken('api')->plainTextToken;
    if ($newToken && $videoId) {
        $denied = api('GET', "videos/$videoId", null, $newToken);
        check('Unenrolled student denied video', in_array($denied['code'], [403, 401], true));
    }
}

// Unverified student login blocked
$unverifiedEmail = 'unverified'.time().'@test.com';
api('POST', 'register', [
    'name' => 'Unverified',
    'email' => $unverifiedEmail,
    'password' => 'password',
    'password_confirmation' => 'password',
]);
$unverifiedLogin = api('POST', 'login', [
    'email' => $unverifiedEmail,
    'password' => 'password',
]);
check(
    'Unverified student login blocked',
    $unverifiedLogin['code'] === 403
    && ($unverifiedLogin['json']['data']['requires_email_verification'] ?? false) === true
);

// Instructor invitation
$service = app(InstructorInvitationService::class);
$testInstructor = User::create([
    'name' => 'Pending Instructor',
    'email' => 'pending'.time().'@rshdacademy.com',
    'role' => UserRole::Instructor,
    'status' => UserStatus::Active,
    'password' => null,
]);
$plain = $service->createInvitation($testInstructor);
check('Invitation token created', strlen($plain) === 64);
check('Token validates before use', $service->validateToken($testInstructor->email, $plain));
$service->setPassword($testInstructor->email, $plain, 'newpassword123');
check('Token deleted after setPassword', DB::table('password_reset_tokens')->where('email', $testInstructor->email)->count() === 0);
check('Token invalid after use', ! $service->validateToken($testInstructor->email, $plain));
$testInstructor->refresh();
check('password_set_at updated', $testInstructor->password_set_at !== null);

// Instructor login without password
$noPass = User::create([
    'name' => 'No Pass',
    'email' => 'nopass'.time().'@rshdacademy.com',
    'role' => UserRole::Instructor,
    'status' => UserStatus::Active,
    'password' => null,
    'password_set_at' => null,
]);
$r = api('POST', 'login', ['email' => $noPass->email, 'password' => 'anything']);
check('Instructor without password gets 403 on API login', $r['code'] === 403);

echo "\n=== Results: $passed passed, $failed failed ===\n";
exit($failed > 0 ? 1 : 0);
