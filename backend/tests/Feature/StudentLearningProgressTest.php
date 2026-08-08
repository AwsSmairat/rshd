<?php

namespace Tests\Feature;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Enums\VideoStatus;
use App\Models\Assignment;
use App\Models\AssignmentSubmission;
use App\Models\Lesson;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use App\Models\VideoWatchProgress;
use App\Services\StudentLearningProgressService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StudentLearningProgressTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_single_part_half_complete_reports_fifty_percent(): void
    {
        [$student, $subject, $lesson] = $this->createSubjectWithStudent();

        $video = $this->createReadyVideo($lesson);
        $assignment = $this->createAssignment($subject, $lesson);

        AssignmentSubmission::query()->create([
            'assignment_id' => $assignment->id,
            'student_id' => $student->id,
            'submitted_at' => now(),
        ]);

        $progress = app(StudentLearningProgressService::class)
            ->progressPercentMapForSubjects($student, collect([$subject->id]));

        $this->assertSame(50.0, $progress[$subject->id]);

        VideoWatchProgress::query()->create([
            'video_id' => $video->id,
            'student_id' => $student->id,
            'watched_seconds' => 100,
            'current_position' => 100,
            'completion_percentage' => 90,
            'replay_count' => 0,
        ]);

        $progress = app(StudentLearningProgressService::class)
            ->progressPercentMapForSubjects($student, collect([$subject->id]));

        $this->assertSame(100.0, $progress[$subject->id]);
    }

    public function test_completed_part_and_new_empty_part_keeps_progress_at_one_hundred(): void
    {
        [$student, $subject, $lesson] = $this->createSubjectWithStudent();

        $video = $this->createReadyVideo($lesson);
        $assignment = $this->createAssignment($subject, $lesson);

        AssignmentSubmission::query()->create([
            'assignment_id' => $assignment->id,
            'student_id' => $student->id,
            'submitted_at' => now(),
        ]);

        VideoWatchProgress::query()->create([
            'video_id' => $video->id,
            'student_id' => $student->id,
            'watched_seconds' => 100,
            'current_position' => 100,
            'completion_percentage' => 90,
            'replay_count' => 0,
        ]);

        Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'محاضرة 2',
            'order' => 2,
            'status' => ContentStatus::Active,
        ]);

        $progress = app(StudentLearningProgressService::class)
            ->progressPercentMapForSubjects($student, collect([$subject->id]));

        $this->assertSame(100.0, $progress[$subject->id]);
    }

    public function test_new_part_with_content_recalculates_progress_downward(): void
    {
        [$student, $subject, $lesson] = $this->createSubjectWithStudent();

        $video = $this->createReadyVideo($lesson);
        $assignment = $this->createAssignment($subject, $lesson);

        AssignmentSubmission::query()->create([
            'assignment_id' => $assignment->id,
            'student_id' => $student->id,
            'submitted_at' => now(),
        ]);

        VideoWatchProgress::query()->create([
            'video_id' => $video->id,
            'student_id' => $student->id,
            'watched_seconds' => 100,
            'current_position' => 100,
            'completion_percentage' => 90,
            'replay_count' => 0,
        ]);

        $lessonTwo = Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'محاضرة 2',
            'order' => 2,
            'status' => ContentStatus::Active,
        ]);

        $this->createReadyVideo($lessonTwo);

        $progress = app(StudentLearningProgressService::class)
            ->progressPercentMapForSubjects($student, collect([$subject->id]));

        $this->assertSame(50.0, $progress[$subject->id]);
    }

    public function test_two_parts_weight_equally_regardless_of_item_count(): void
    {
        [$student, $subject, $lessonOne] = $this->createSubjectWithStudent();

        $lessonTwo = Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'محاضرة 2',
            'order' => 2,
            'status' => ContentStatus::Active,
        ]);

        $this->createReadyVideo($lessonOne);
        $this->createReadyVideo($lessonOne);
        $this->createReadyVideo($lessonOne);

        $videoTwo = $this->createReadyVideo($lessonTwo);

        VideoWatchProgress::query()->create([
            'video_id' => $videoTwo->id,
            'student_id' => $student->id,
            'watched_seconds' => 100,
            'current_position' => 100,
            'completion_percentage' => 90,
            'replay_count' => 0,
        ]);

        $progress = app(StudentLearningProgressService::class)
            ->progressPercentMapForSubjects($student, collect([$subject->id]));

        $this->assertSame(50.0, $progress[$subject->id]);
    }

    public function test_my_subjects_endpoint_returns_lesson_based_progress(): void
    {
        [$student, $subject, $lesson] = $this->createSubjectWithStudent();

        $this->createReadyVideo($lesson);
        $assignment = $this->createAssignment($subject, $lesson);

        AssignmentSubmission::query()->create([
            'assignment_id' => $assignment->id,
            'student_id' => $student->id,
            'submitted_at' => now(),
        ]);

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/my-subjects')
            ->assertOk()
            ->assertJsonPath('data.0.progress_percent', 50);
    }

    /**
     * @return array{0: User, 1: Subject, 2: Lesson}
     */
    private function createSubjectWithStudent(): array
    {
        $instructor = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
        ]);

        $subject = Subject::query()->create([
            'instructor_id' => $instructor->id,
            'title' => 'ميكانيكا المواد',
            'description' => 'Test subject',
            'category' => SubjectCategory::Engineering,
            'status' => ContentStatus::Active,
            'price' => 40,
        ]);

        $lesson = Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'المحاضرة 1',
            'order' => 1,
            'status' => ContentStatus::Active,
        ]);

        $student = User::factory()->create([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
        ]);

        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
            'payment_status' => PaymentStatus::Paid,
            'access_status' => AccessStatus::Active,
        ]);

        return [$student, $subject, $lesson];
    }

    private function createReadyVideo(Lesson $lesson): Video
    {
        return Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'فيديو',
            'storage_provider' => 'local',
            'video_url' => '',
            'video_path' => 'videos/test.mp4',
            'duration_seconds' => 120,
            'status' => VideoStatus::Ready,
            'is_free' => false,
        ]);
    }

    private function createAssignment(Subject $subject, Lesson $lesson): Assignment
    {
        return Assignment::query()->create([
            'subject_id' => $subject->id,
            'lesson_id' => $lesson->id,
            'title' => 'واجب',
            'description' => 'Test assignment',
            'due_date' => now()->addWeek(),
            'status' => ContentStatus::Active,
        ]);
    }
}
