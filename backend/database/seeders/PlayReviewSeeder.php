<?php

namespace Database\Seeders;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\FileType;
use App\Enums\LessonFileStorageStatus;
use App\Enums\PaymentStatus;
use App\Enums\QuestionType;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Enums\VideoStatus;
use App\Models\Assignment;
use App\Models\Lesson;
use App\Models\LessonFile;
use App\Models\Quiz;
use App\Models\QuizAnswer;
use App\Models\QuizQuestion;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use App\Services\DeviceService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class PlayReviewSeeder extends Seeder
{
    public const SUBJECT_TITLE = 'مادة مراجعة Google Play';

    public const LESSON_TITLE = 'درس مراجعة التطبيق';

    public const REVIEW_FILE_PATH = 'review/google-play-review.pdf';

    public function run(): void
    {
        $email = $this->requiredEnvironmentValue('PLAY_REVIEW_EMAIL');
        $password = $this->requiredEnvironmentValue('PLAY_REVIEW_PASSWORD');

        if (! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new RuntimeException('PLAY_REVIEW_EMAIL must be a valid email address.');
        }

        if (mb_strlen($password) < 12) {
            throw new RuntimeException('PLAY_REVIEW_PASSWORD must contain at least 12 characters.');
        }

        $admin = User::query()
            ->where('role', UserRole::Admin->value)
            ->where('status', UserStatus::Active->value)
            ->orderBy('id')
            ->first();

        if ($admin === null) {
            throw new RuntimeException('An active admin account is required before running PlayReviewSeeder.');
        }

        $reviewer = User::query()->where('email', $email)->first();

        if ($reviewer !== null
            && (! $reviewer->isStudent()
                || $reviewer->preference(DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE, false) !== true)) {
            throw new RuntimeException('PLAY_REVIEW_EMAIL already belongs to a non-review account.');
        }

        if ($reviewer === null) {
            $reviewer = new User(['email' => $email]);
        }

        $preferences = is_array($reviewer->preferences) ? $reviewer->preferences : [];
        $preferences[DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE] = true;

        $reviewer->fill([
            'name' => 'Google Play Reviewer',
            'password' => Hash::make($password),
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
            'password_set_at' => now(),
            'preferences' => $preferences,
        ]);
        $reviewer->save();

        $subject = Subject::query()->updateOrCreate(
            [
                'instructor_id' => $admin->id,
                'title' => self::SUBJECT_TITLE,
            ],
            [
                'description' => 'محتوى مخصص لمراجعة وظائف تطبيق RSHD Academy في متجر Google Play.',
                'category' => SubjectCategory::It,
                'status' => ContentStatus::Active,
                'price' => 0,
            ],
        );

        $lesson = Lesson::query()->updateOrCreate(
            [
                'subject_id' => $subject->id,
                'title' => self::LESSON_TITLE,
            ],
            [
                'description' => 'يتضمن هذا الدرس فيديو وملف PDF وواجباً واختباراً لاختبار مسارات التطبيق الأساسية.',
                'order' => 1,
                'status' => ContentStatus::Active,
            ],
        );

        Video::query()->updateOrCreate(
            [
                'lesson_id' => $lesson->id,
                'title' => 'فيديو مراجعة التطبيق',
            ],
            [
                'storage_provider' => 'demo',
                'video_url' => 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
                'video_path' => null,
                'external_video_id' => null,
                'original_file_name' => 'Google Play review sample video',
                'file_size' => null,
                'file_mime_type' => 'video/mp4',
                'duration_seconds' => 15,
                'status' => VideoStatus::Ready,
                'is_free' => false,
            ],
        );

        $pdf = $this->reviewPdf();

        if (! Storage::disk('lesson_files')->put(self::REVIEW_FILE_PATH, $pdf)) {
            throw new RuntimeException('Failed to write Google Play review PDF.');
        }

        LessonFile::query()->updateOrCreate(
            [
                'lesson_id' => $lesson->id,
                'title' => 'ملف PDF للمراجعة',
            ],
            [
                'file_type' => FileType::Pdf,
                'file_path' => self::REVIEW_FILE_PATH,
                'original_file_name' => 'rshd-google-play-review.pdf',
                'file_url' => '',
                'file_size' => strlen($pdf),
                'file_mime_type' => 'application/pdf',
                'storage_provider' => 'local',
                'storage_disk' => 'lesson_files',
                'external_path' => null,
                'storage_status' => LessonFileStorageStatus::Ready,
                'uploaded_at' => now(),
            ],
        );

        Assignment::query()->updateOrCreate(
            [
                'subject_id' => $subject->id,
                'title' => 'واجب مراجعة التطبيق',
            ],
            [
                'lesson_id' => $lesson->id,
                'description' => 'اكتب جملة قصيرة للتأكد من أن إرسال الواجب يعمل بشكل صحيح.',
                'due_date' => now()->addDays(30),
                'status' => ContentStatus::Active,
            ],
        );

        $quiz = Quiz::query()->updateOrCreate(
            [
                'subject_id' => $subject->id,
                'title' => 'اختبار مراجعة التطبيق',
            ],
            [
                'lesson_id' => $lesson->id,
                'description' => 'اختبار قصير للتحقق من مسار الاختبارات داخل التطبيق.',
                'duration_minutes' => 10,
                'status' => ContentStatus::Active,
            ],
        );

        $question = QuizQuestion::query()->updateOrCreate(
            [
                'quiz_id' => $quiz->id,
                'question_text' => 'هل يمكنك مشاهدة هذا السؤال داخل تطبيق RSHD Academy؟',
            ],
            [
                'question_type' => QuestionType::TrueFalse,
                'points' => 1,
            ],
        );

        QuizAnswer::query()->updateOrCreate(
            [
                'question_id' => $question->id,
                'answer_text' => 'صح',
            ],
            ['is_correct' => true],
        );

        QuizAnswer::query()->updateOrCreate(
            [
                'question_id' => $question->id,
                'answer_text' => 'خطأ',
            ],
            ['is_correct' => false],
        );

        SubjectStudent::query()->updateOrCreate(
            [
                'subject_id' => $subject->id,
                'student_id' => $reviewer->id,
            ],
            [
                'activated_by' => $admin->id,
                'payment_status' => PaymentStatus::Paid,
                'sale_price' => 0,
                'paid_at' => now(),
                'access_status' => AccessStatus::Active,
                'activated_at' => now(),
                'expires_at' => null,
            ],
        );
    }

    protected function requiredEnvironmentValue(string $key): string
    {
        $value = getenv($key);

        if (! is_string($value) || trim($value) === '') {
            throw new RuntimeException($key.' must be provided when running PlayReviewSeeder.');
        }

        return trim($value);
    }

    protected function reviewPdf(): string
    {
        $stream = "BT\n/F1 18 Tf\n72 720 Td\n(RSHD Academy - Google Play Review File) Tj\nET\n";

        $objects = [
            '<< /Type /Catalog /Pages 2 0 R >>',
            '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
            '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>',
            "<< /Length ".strlen($stream)." >>\nstream\n".$stream."endstream",
            '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
        ];

        $pdf = "%PDF-1.4\n";
        $offsets = [0];

        foreach ($objects as $index => $object) {
            $offsets[] = strlen($pdf);
            $number = $index + 1;
            $pdf .= $number." 0 obj\n".$object."\nendobj\n";
        }

        $xrefOffset = strlen($pdf);
        $pdf .= "xref\n0 ".(count($objects) + 1)."\n";
        $pdf .= "0000000000 65535 f \n";

        foreach (array_slice($offsets, 1) as $offset) {
            $pdf .= sprintf("%010d 00000 n \n", $offset);
        }

        $pdf .= "trailer\n<< /Size ".(count($objects) + 1)." /Root 1 0 R >>\n";
        $pdf .= "startxref\n".$xrefOffset."\n%%EOF\n";

        return $pdf;
    }
}
