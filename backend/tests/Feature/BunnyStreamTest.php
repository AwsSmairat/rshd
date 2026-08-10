<?php

namespace Tests\Feature;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Enums\VideoStatus;
use App\Filament\Resources\VideoResource;
use App\Jobs\UploadVideoToBunnyJob;
use App\Models\Lesson;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use App\Services\Bunny\BunnyCdnTokenSigner;
use App\Services\Bunny\BunnyStreamConfigValidator;
use App\Services\Bunny\BunnyStreamService;
use App\Services\Bunny\BunnyStreamStatusMapper;
use App\Services\Bunny\BunnyStreamWebhookService;
use App\Services\Video\BunnyStreamVideoProvider;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BunnyStreamTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Storage::fake('lesson_videos');

        Config::set('video.provider', 'bunny');
        Config::set('video.bunny.library_id', '12345');
        Config::set('video.bunny.api_key', 'stream-api-key');
        Config::set('video.bunny.read_only_api_key', 'read-only-key');
        Config::set('video.bunny.token_key', 'cdn-token-key');
        Config::set('video.bunny.cdn_hostname', 'vz-test.b-cdn.net');
        Config::set('video.bunny.token_ip_binding', false);
        Config::set('video.bunny.playback_mode', 'embed');
        Config::set('video.signing_key', 'test-signing-key');
        Config::set('video.playback_ttl', 600);
    }

    public function test_status_mapper_maps_api_and_webhook_statuses(): void
    {
        $mapper = app(BunnyStreamStatusMapper::class);

        $this->assertSame(VideoStatus::Uploading, $mapper->fromApiStatus(0));
        $this->assertSame(VideoStatus::Processing, $mapper->fromApiStatus(2));
        $this->assertSame(VideoStatus::Ready, $mapper->fromApiStatus(4));
        $this->assertSame(VideoStatus::Failed, $mapper->fromApiStatus(5));

        $this->assertSame(VideoStatus::Processing, $mapper->fromWebhookStatus(2));
        $this->assertSame(VideoStatus::Ready, $mapper->fromWebhookStatus(3));
        $this->assertSame(VideoStatus::Failed, $mapper->fromWebhookStatus(5));
    }

    public function test_cdn_token_signer_uses_directory_path_for_hls(): void
    {
        $signer = app(BunnyCdnTokenSigner::class);

        $url = $signer->signUrl(
            url: 'https://vz-test.b-cdn.net/abc-guid/playlist.m3u8',
            securityKey: 'cdn-token-key',
            expiresAt: 1_700_000_000,
            isDirectory: true,
            pathAllowed: '/abc-guid/',
        );

        $this->assertStringContainsString('/bcdn_token=HS256-', $url);
        $this->assertStringContainsString('token_path=', $url);
        $this->assertStringContainsString('/abc-guid/playlist.m3u8', $url);
        $this->assertStringNotContainsString('cdn-token-key', $url);
    }

    public function test_upload_job_creates_bunny_video_and_stores_external_id(): void
    {
        Http::fake([
            'video.bunnycdn.com/library/12345/videos' => Http::response([
                'guid' => 'bunny-guid-1',
                'title' => 'Test',
                'status' => 1,
            ], 200),
            'video.bunnycdn.com/library/12345/videos/bunny-guid-1' => Http::response([
                'success' => true,
            ], 200),
        ]);

        $video = $this->createLocalVideoForBunny();

        (new UploadVideoToBunnyJob($video->id))->handle(app(BunnyStreamService::class));

        $video->refresh();

        $this->assertSame('bunny', $video->storage_provider);
        $this->assertSame('bunny-guid-1', $video->external_video_id);
        $this->assertSame(VideoStatus::Processing, $video->status);
    }

    public function test_sync_updates_video_to_ready_from_bunny_api(): void
    {
        Http::fake([
            'video.bunnycdn.com/library/12345/videos/bunny-guid-2' => Http::response([
                'guid' => 'bunny-guid-2',
                'status' => 4,
                'length' => 180,
            ], 200),
        ]);

        $video = Video::query()->create([
            'lesson_id' => $this->createLesson($this->createSubject())->id,
            'title' => 'Bunny ready',
            'storage_provider' => 'bunny',
            'video_url' => '',
            'external_video_id' => 'bunny-guid-2',
            'duration_seconds' => 0,
            'status' => VideoStatus::Processing,
            'is_free' => false,
        ]);

        app(BunnyStreamService::class)->syncVideoStatus($video);

        $video->refresh();

        $this->assertSame(VideoStatus::Ready, $video->status);
        $this->assertSame(180, $video->duration_seconds);
    }

    public function test_enrolled_student_receives_signed_bunny_playback_url(): void
    {
        Config::set('video.bunny.playback_mode', 'cdn');

        [$student, $video] = $this->createBunnyVideoScenario();

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/videos/'.$video->id)
            ->assertOk();

        $playbackUrl = (string) $response->json('data.playback.url');

        $this->assertStringContainsString('vz-test.b-cdn.net', $playbackUrl);
        $this->assertStringContainsString('/bcdn_token=HS256-', $playbackUrl);
        $this->assertStringContainsString('/bunny-guid-3/playlist.m3u8', $playbackUrl);
        $this->assertSame('hls', $response->json('data.playback.type'));

        $payload = json_encode($response->json(), JSON_THROW_ON_ERROR);
        $this->assertStringNotContainsString('stream-api-key', $payload);
        $this->assertStringNotContainsString('cdn-token-key', $payload);
        $this->assertStringNotContainsString('external_video_id', $payload);
    }

    public function test_unauthorized_student_cannot_get_bunny_playback(): void
    {
        $video = $this->createBunnyVideo();
        $other = $this->createStudent(['email' => 'bunny-other@rshdacademy.com']);

        Sanctum::actingAs($other);

        $this->getJson('/api/v1/videos/'.$video->id)->assertForbidden();
    }

    public function test_webhook_updates_video_status_when_signature_is_valid(): void
    {
        Queue::fake();

        $video = $this->createBunnyVideo('bunny-guid-4');

        $rawBody = '{"VideoLibraryId":12345,"VideoGuid":"bunny-guid-4","Status":3}';

        $this->postBunnyStreamWebhook($rawBody, [
            'HTTP_X-BunnyStream-Signature' => $this->signBunnyStreamWebhookBody($rawBody),
        ])->assertOk();

        $this->assertSame(VideoStatus::Ready, $video->fresh()->status);
    }

    public function test_webhook_rejects_missing_signature(): void
    {
        $rawBody = '{"VideoGuid":"bunny-guid-4","Status":3}';

        $this->postBunnyStreamWebhook($rawBody, [
            'HTTP_X-BunnyStream-Signature' => '',
        ])->assertUnauthorized();
    }

    public function test_webhook_rejects_invalid_signature(): void
    {
        $rawBody = '{"VideoGuid":"invalid","Status":3}';

        $this->postBunnyStreamWebhook($rawBody, [
            'HTTP_X-BunnyStream-Signature' => str_repeat('a', 64),
        ])->assertUnauthorized();
    }

    public function test_webhook_rejects_invalid_signature_version(): void
    {
        $rawBody = '{"VideoGuid":"bunny-guid-4","Status":3}';

        $this->postBunnyStreamWebhook($rawBody, [
            'HTTP_X-BunnyStream-Signature-Version' => 'v2',
            'HTTP_X-BunnyStream-Signature' => $this->signBunnyStreamWebhookBody($rawBody),
        ])->assertUnauthorized();
    }

    public function test_webhook_rejects_invalid_signature_algorithm(): void
    {
        $rawBody = '{"VideoGuid":"bunny-guid-4","Status":3}';

        $this->postBunnyStreamWebhook($rawBody, [
            'HTTP_X-BunnyStream-Signature-Algorithm' => 'sha256',
            'HTTP_X-BunnyStream-Signature' => $this->signBunnyStreamWebhookBody($rawBody),
        ])->assertUnauthorized();
    }

    public function test_webhook_rejects_reserialized_body_when_signature_uses_original_raw_bytes(): void
    {
        $signedBody = '{"VideoGuid":"bunny-guid-4","Status":3,"VideoLibraryId":12345}';
        $reserializedBody = json_encode([
            'Status' => 3,
            'VideoLibraryId' => 12345,
            'VideoGuid' => 'bunny-guid-4',
        ], JSON_THROW_ON_ERROR);

        $this->assertNotSame($signedBody, $reserializedBody);

        $this->postBunnyStreamWebhook($reserializedBody, [
            'HTTP_X-BunnyStream-Signature' => $this->signBunnyStreamWebhookBody($signedBody),
        ])->assertUnauthorized();
    }

    public function test_webhook_validation_uses_constant_time_comparison(): void
    {
        $service = app(BunnyStreamWebhookService::class);
        $rawBody = '{"Status":3}';

        $validSignature = $this->signBunnyStreamWebhookBody($rawBody);
        $request = Request::create('/webhooks/bunny/stream', 'POST', [], [], [], [
            'HTTP_X-BunnyStream-Signature-Version' => 'v1',
            'HTTP_X-BunnyStream-Signature-Algorithm' => 'hmac-sha256',
            'HTTP_X-BunnyStream-Signature' => $validSignature,
            'CONTENT_TYPE' => 'application/json',
        ], $rawBody);

        $this->assertTrue($service->validateSignature($request, $rawBody));
    }

    public function test_webhook_does_not_log_secrets(): void
    {
        Queue::fake();

        $this->createBunnyVideo('bunny-guid-log');

        $loggedMessages = [];
        Log::listen(function ($message) use (&$loggedMessages): void {
            $loggedMessages[] = is_string($message->message)
                ? $message->message
                : json_encode($message->message, JSON_THROW_ON_ERROR);
        });

        $rawBody = '{"VideoLibraryId":12345,"VideoGuid":"bunny-guid-log","Status":3}';
        $signature = $this->signBunnyStreamWebhookBody($rawBody);

        $this->postBunnyStreamWebhook($rawBody, [
            'HTTP_X-BunnyStream-Signature' => $signature,
        ])->assertOk();

        $combined = implode("\n", $loggedMessages);

        $this->assertStringNotContainsString('read-only-key', $combined);
        $this->assertStringNotContainsString($signature, $combined);
    }

    public function test_prepare_video_data_sets_storage_provider_for_bunny_uploads(): void
    {
        Storage::disk('lesson_videos')->put('lesson-videos/bunny-create.mp4', 'video-bytes');

        $prepared = VideoResource::prepareVideoData([
            'lesson_id' => 1,
            'title' => 'Bunny upload',
            'video_path' => 'lesson-videos/bunny-create.mp4',
            'original_file_name' => 'bunny-create.mp4',
            'status' => VideoStatus::Ready->value,
            'is_free' => false,
        ]);

        $this->assertSame('bunny', $prepared['storage_provider']);
        $this->assertSame(VideoStatus::Uploading->value, $prepared['status']);
        $this->assertNull($prepared['external_video_id']);
    }

    public function test_video_model_sets_storage_provider_on_create_when_missing(): void
    {
        Config::set('video.provider', 'bunny');

        $lessonId = $this->createLesson($this->createSubject())->id;

        $video = Video::query()->create([
            'lesson_id' => $lessonId,
            'title' => 'Fallback provider',
            'video_url' => '',
            'status' => VideoStatus::Uploading,
            'is_free' => false,
        ]);

        $this->assertSame('bunny', $video->storage_provider);
    }

    public function test_bunny_config_validator_warns_when_token_key_matches_hostname_prefix(): void
    {
        Config::set('video.provider', 'bunny');
        Config::set('video.bunny.cdn_hostname', 'vz-example.b-cdn.net');
        Config::set('video.bunny.token_key', 'vz-example');

        Log::shouldReceive('critical')
            ->once()
            ->with('bunny.stream.token_key_looks_like_hostname', \Mockery::type('array'));

        BunnyStreamConfigValidator::warnIfMisconfigured();
    }

    public function test_migrate_to_bunny_command_queues_eligible_videos(): void
    {
        Queue::fake();

        $video = $this->createLocalVideoForBunny();

        $this->artisan('videos:migrate-to-bunny')
            ->assertSuccessful();

        Queue::assertPushed(UploadVideoToBunnyJob::class, fn (UploadVideoToBunnyJob $job): bool => $job->videoId === $video->id);
    }

    public function test_migrate_to_bunny_command_queues_stuck_bunny_uploads(): void
    {
        Queue::fake();

        Storage::disk('lesson_videos')->put('lesson-videos/stuck.mp4', 'video-bytes');

        $video = Video::query()->create([
            'lesson_id' => $this->createLesson($this->createSubject())->id,
            'title' => 'Stuck Bunny upload',
            'storage_provider' => 'bunny',
            'video_url' => '',
            'video_path' => 'lesson-videos/stuck.mp4',
            'duration_seconds' => 0,
            'status' => VideoStatus::Uploading,
            'is_free' => false,
        ]);

        $this->artisan('videos:migrate-to-bunny', ['--video' => (string) $video->id])
            ->assertSuccessful();

        Queue::assertPushed(UploadVideoToBunnyJob::class, fn (UploadVideoToBunnyJob $job): bool => $job->videoId === $video->id);
    }

    public function test_bunny_provider_generates_playback_with_expiry(): void
    {
        Config::set('video.bunny.playback_mode', 'cdn');

        [$student, $video] = $this->createBunnyVideoScenario(
            expiresAt: now()->addSeconds(120),
        );

        $playback = app(BunnyStreamVideoProvider::class)
            ->generateSignedPlaybackUrl($video, $student);

        $this->assertStringContainsString('playlist.m3u8', $playback['url']);
        $this->assertSame('hls', $playback['type']);
        $this->assertTrue($playback['expires_at']->lte(now()->addSeconds(120)));
    }

    public function test_bunny_provider_generates_embed_playback_url_by_default(): void
    {
        [$student, $video] = $this->createBunnyVideoScenario(
            expiresAt: now()->addSeconds(120),
        );

        $playback = app(BunnyStreamVideoProvider::class)
            ->generateSignedPlaybackUrl($video, $student);

        $this->assertStringContainsString('iframe.mediadelivery.net/embed/12345/bunny-guid-3', $playback['url']);
        $this->assertSame('embed', $playback['type']);
    }

    public function test_embed_token_is_appended_when_embed_key_configured(): void
    {
        Config::set('video.bunny.embed_token_key', 'embed-secret-key');

        [$student, $video] = $this->createBunnyVideoScenario();

        $playback = app(BunnyStreamVideoProvider::class)
            ->generateSignedPlaybackUrl($video, $student);

        $this->assertStringContainsString('token=', $playback['url']);
        $this->assertStringContainsString('expires=', $playback['url']);
        $this->assertStringContainsString(
            hash('sha256', 'embed-secret-keybunny-guid-3'.$playback['expires_at']->getTimestamp()),
            $playback['url'],
        );
    }

    public function test_bunny_video_uses_local_fallback_when_staged_file_exists(): void
    {
        Config::set('video.bunny.local_fallback', true);

        Storage::disk('lesson_videos')->put('lesson-videos/bunny-local.mp4', 'video-bytes');

        $student = $this->createStudent();
        $subject = $this->createSubject();
        $lesson = $this->createLesson($subject);

        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
            'payment_status' => PaymentStatus::Paid,
            'access_status' => AccessStatus::Active,
            'activated_at' => now(),
        ]);

        $video = Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'Bunny with local copy',
            'storage_provider' => 'bunny',
            'video_url' => '',
            'video_path' => 'lesson-videos/bunny-local.mp4',
            'external_video_id' => 'bunny-guid-local',
            'duration_seconds' => 16,
            'status' => VideoStatus::Ready,
            'is_free' => false,
        ]);

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/videos/'.$video->id)
            ->assertOk();

        $playbackUrl = (string) $response->json('data.playback.url');

        $this->assertStringContainsString('/api/v1/videos/'.$video->id.'/stream', $playbackUrl);
        $this->assertSame('hls', $response->json('data.playback.type'));
    }

    /**
     * @return array{0: User, 1: Video}
     */
    protected function createBunnyVideoScenario(?Carbon $expiresAt = null): array
    {
        $student = $this->createStudent();
        $subject = $this->createSubject();
        $lesson = $this->createLesson($subject);

        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
            'payment_status' => PaymentStatus::Paid,
            'access_status' => AccessStatus::Active,
            'activated_at' => now(),
            'expires_at' => $expiresAt,
        ]);

        return [$student, $this->createBunnyVideo('bunny-guid-3', $lesson)];
    }

    protected function createBunnyVideo(string $externalId = 'bunny-guid-1', ?Lesson $lesson = null): Video
    {
        $lesson ??= $this->createLesson($this->createSubject());

        return Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'Bunny Video',
            'storage_provider' => 'bunny',
            'video_url' => '',
            'external_video_id' => $externalId,
            'duration_seconds' => 120,
            'status' => VideoStatus::Ready,
            'is_free' => false,
        ]);
    }

    protected function createLocalVideoForBunny(): Video
    {
        Storage::disk('lesson_videos')->put('lesson-videos/local.mp4', 'local-video');

        return Video::query()->create([
            'lesson_id' => $this->createLesson($this->createSubject())->id,
            'title' => 'Local to Bunny',
            'storage_provider' => 'local',
            'video_url' => '',
            'video_path' => 'lesson-videos/local.mp4',
            'duration_seconds' => 0,
            'status' => VideoStatus::Uploading,
            'is_free' => false,
        ]);
    }

    protected function createSubject(?User $instructor = null): Subject
    {
        $instructor ??= User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ]);

        return Subject::query()->create([
            'instructor_id' => $instructor->id,
            'title' => 'مادة Bunny',
            'description' => 'وصف',
            'category' => SubjectCategory::General->value,
            'status' => ContentStatus::Active,
            'price' => 10,
        ]);
    }

    protected function createLesson(Subject $subject): Lesson
    {
        return Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'درس Bunny',
            'description' => 'وصف',
            'status' => ContentStatus::Active,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     */
    protected function postBunnyStreamWebhook(string $rawBody, array $headers = []): TestResponse
    {
        $defaults = [
            'CONTENT_TYPE' => 'application/json',
            'HTTP_X-BunnyStream-Signature-Version' => 'v1',
            'HTTP_X-BunnyStream-Signature-Algorithm' => 'hmac-sha256',
        ];

        return $this->call(
            'POST',
            '/api/v1/webhooks/bunny/stream',
            [],
            [],
            [],
            array_merge($defaults, $headers),
            $rawBody,
        );
    }

    protected function signBunnyStreamWebhookBody(string $rawBody, string $secret = 'read-only-key'): string
    {
        return hash_hmac('sha256', $rawBody, $secret);
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    protected function createStudent(array $overrides = []): User
    {
        $student = User::factory()->create(array_merge([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ], $overrides));

        $student->assignRole('student');

        return $student;
    }
}
