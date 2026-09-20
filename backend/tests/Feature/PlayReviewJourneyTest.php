<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Assignment;
use App\Models\AssignmentSubmission;
use App\Models\Lesson;
use App\Models\LessonFile;
use App\Models\Quiz;
use App\Models\QuizAnswer;
use App\Models\QuizAttempt;
use App\Models\QuizQuestion;
use App\Models\Subject;
use App\Models\User;
use App\Models\Video;
use App\Services\DeviceService;
use App\Services\PlatformSettingsService;
use Database\Seeders\PlayReviewSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PlayReviewJourneyTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        putenv('PLAY_REVIEW_EMAIL');
        putenv('PLAY_REVIEW_PASSWORD');

        parent::tearDown();
    }

    public function test_google_play_reviewer_can_complete_the_core_student_journey(): void
    {
        Storage::fake('lesson_files');

        config([
            'video.signed_playback' => true,
            'app.url' => 'http://localhost',
        ]);

        User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
        ]);

        /** @var PlatformSettingsService $settings */
        $settings = app(PlatformSettingsService::class);
        $settings->set('email_verification_required', true, 'registration');
        $settings->set('device_binding_enabled', true, 'students');
        $settings->set('device_id_required', true, 'students');
        $settings->set('max_active_devices', 1, 'students');

        putenv('PLAY_REVIEW_EMAIL=google-reviewer@rshd.test');
        putenv('PLAY_REVIEW_PASSWORD=review-password-12345');

        $this->seed(PlayReviewSeeder::class);

        $reviewer = User::query()
            ->where('email', 'google-reviewer@rshd.test')
            ->firstOrFail();

        $this->assertTrue(
            (bool) $reviewer->preference(DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE),
        );

        $firstLogin = $this->postJson('/api/v1/login', [
            'email' => $reviewer->email,
            'password' => 'review-password-12345',
            'device_id' => 'google-review-device-a',
            'device_name' => 'Google Play Review Device A',
            'platform' => 'android',
        ]);

        $firstLogin
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['token', 'user']]);

        $secondLogin = $this->postJson('/api/v1/login', [
            'email' => $reviewer->email,
            'password' => 'review-password-12345',
            'device_id' => 'google-review-device-b',
            'device_name' => 'Google Play Review Device B',
            'platform' => 'android',
        ]);

        $secondLogin
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['token', 'user']]);

        $token = (string) $secondLogin->json('data.token');

        $this->assertNotSame('', $token);
        $this->assertSame(
            0,
            $reviewer->studentDevices()->where('is_active', true)->count(),
        );

        $subject = Subject::query()
            ->where('title', PlayReviewSeeder::SUBJECT_TITLE)
            ->firstOrFail();

        $lesson = Lesson::query()
            ->where('subject_id', $subject->id)
            ->where('title', PlayReviewSeeder::LESSON_TITLE)
            ->firstOrFail();

        $video = Video::query()
            ->where('lesson_id', $lesson->id)
            ->firstOrFail();

        $lessonFile = LessonFile::query()
            ->where('lesson_id', $lesson->id)
            ->firstOrFail();

        $assignment = Assignment::query()
            ->where('subject_id', $subject->id)
            ->firstOrFail();

        $quiz = Quiz::query()
            ->where('subject_id', $subject->id)
            ->firstOrFail();

        $this->withToken($token)
            ->getJson('/api/v1/my-subjects')
            ->assertOk()
            ->assertJsonFragment([
                'id' => $subject->id,
                'title' => PlayReviewSeeder::SUBJECT_TITLE,
            ]);

        $this->withToken($token)
            ->getJson("/api/v1/subjects/{$subject->id}/lessons")
            ->assertOk()
            ->assertJsonFragment([
                'id' => $lesson->id,
                'title' => PlayReviewSeeder::LESSON_TITLE,
            ]);

        $this->withToken($token)
            ->getJson("/api/v1/lessons/{$lesson->id}")
            ->assertOk()
            ->assertJsonFragment(['id' => $video->id, 'title' => $video->title])
            ->assertJsonFragment(['id' => $lessonFile->id, 'title' => $lessonFile->title])
            ->assertJsonFragment(['id' => $assignment->id, 'title' => $assignment->title])
            ->assertJsonFragment(['id' => $quiz->id, 'title' => $quiz->title]);

        $playback = $this->withToken($token)
            ->getJson("/api/v1/videos/{$video->id}/playback");

        $playback
            ->assertOk()
            ->assertJsonPath('data.id', $video->id)
            ->assertJsonStructure(['data' => ['playback' => ['url', 'expires_at', 'type']]]);

        $playbackUrl = (string) $playback->json('data.playback.url');
        $this->assertStringContainsString("/api/v1/videos/{$video->id}/stream", $playbackUrl);

        $this->get($this->requestTarget($playbackUrl))
            ->assertStatus(302)
            ->assertRedirect($video->video_url);

        $this->withToken($token)
            ->getJson("/api/v1/files/{$lessonFile->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $lessonFile->id)
            ->assertJsonPath('data.is_locked', false)
            ->assertJsonPath('data.requires_signed_download', true);

        $download = $this->withToken($token)
            ->getJson("/api/v1/files/{$lessonFile->id}/download");

        $download
            ->assertOk()
            ->assertJsonStructure(['data' => ['url', 'expires_at']]);

        $downloadUrl = (string) $download->json('data.url');
        $this->assertStringContainsString("/api/v1/files/{$lessonFile->id}/stream", $downloadUrl);

        $this->get($this->requestTarget($downloadUrl))
            ->assertOk()
            ->assertHeader('content-type', 'application/pdf');

        $this->withToken($token)
            ->getJson('/api/v1/assignments')
            ->assertOk()
            ->assertJsonFragment([
                'id' => $assignment->id,
                'title' => $assignment->title,
            ]);

        $this->withToken($token)
            ->postJson("/api/v1/assignments/{$assignment->id}/submit", [
                'answer_text' => 'إجابة مراجعة Google Play لاختبار رحلة تسليم الواجب.',
            ])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('assignment_submissions', [
            'assignment_id' => $assignment->id,
            'student_id' => $reviewer->id,
        ]);

        $this->withToken($token)
            ->getJson('/api/v1/quizzes')
            ->assertOk()
            ->assertJsonFragment([
                'id' => $quiz->id,
                'title' => $quiz->title,
            ]);

        $start = $this->withToken($token)
            ->postJson("/api/v1/quizzes/{$quiz->id}/start");

        $start
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.quiz.id', $quiz->id)
            ->assertJsonStructure([
                'data' => [
                    'attempt_id',
                    'quiz' => [
                        'questions',
                    ],
                ],
            ]);

        $question = QuizQuestion::query()
            ->where('quiz_id', $quiz->id)
            ->firstOrFail();

        $correctAnswer = QuizAnswer::query()
            ->where('question_id', $question->id)
            ->where('is_correct', true)
            ->firstOrFail();

        $submitQuiz = $this->withToken($token)
            ->postJson("/api/v1/quizzes/{$quiz->id}/submit", [
                'answers' => [
                    [
                        'question_id' => $question->id,
                        'answer_id' => $correctAnswer->id,
                ],
            ],
        ]);

        $submitQuiz
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertSame(100.0, (float) $submitQuiz->json('data.score'));

        $this->assertTrue(
            QuizAttempt::query()
                ->where('quiz_id', $quiz->id)
                ->where('student_id', $reviewer->id)
                ->whereNotNull('submitted_at')
                ->exists(),
        );

        $this->assertTrue(
            AssignmentSubmission::query()
                ->where('assignment_id', $assignment->id)
                ->where('student_id', $reviewer->id)
                ->whereNotNull('submitted_at')
                ->exists(),
        );
    }

    protected function requestTarget(string $url): string
    {
        $parts = parse_url($url);

        $path = is_array($parts) && isset($parts['path'])
            ? (string) $parts['path']
            : '/';

        $query = is_array($parts) && isset($parts['query'])
            ? (string) $parts['query']
            : '';

        return $query !== '' ? $path.'?'.$query : $path;
    }
}
