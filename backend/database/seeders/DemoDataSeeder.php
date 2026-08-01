<?php

namespace Database\Seeders;

use App\Enums\AccessStatus;
use App\Enums\AnnouncementTargetType;
use App\Enums\AnnouncementType;
use App\Enums\ContentStatus;
use App\Enums\FileType;
use App\Enums\GradeSourceType;
use App\Enums\PaymentStatus;
use App\Enums\QuestionType;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Enums\VideoStatus;
use App\Models\Announcement;
use App\Models\AppNotification;
use App\Models\Assignment;
use App\Models\AssignmentSubmission;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\LessonFile;
use App\Models\Quiz;
use App\Models\QuizAnswer;
use App\Models\QuizAttempt;
use App\Models\QuizQuestion;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::updateOrCreate(
            ['email' => 'admin@rshdacademy.com'],
            [
                'name' => 'RSHD Admin',
                'password' => Hash::make('password'),
                'role' => UserRole::Admin,
                'status' => UserStatus::Active,
                'password_set_at' => now(),
            ]
        );
        $admin->syncRoles([UserRole::Admin->value]);

        $instructor = User::updateOrCreate(
            ['email' => 'instructor@rshdacademy.com'],
            [
                'name' => 'د. محمد العبدالله',
                'password' => Hash::make('password'),
                'role' => UserRole::Instructor,
                'status' => UserStatus::Active,
                'password_set_at' => now(),
            ]
        );
        $instructor->syncRoles([UserRole::Instructor->value]);

        $student = User::updateOrCreate(
            ['email' => 'student@rshdacademy.com'],
            [
                'name' => 'أوس السميات',
                'phone' => '07901234567',
                'password' => Hash::make('password'),
                'role' => UserRole::Student,
                'status' => UserStatus::Active,
                'password_set_at' => now(),
                'email_verified_at' => now(),
            ]
        );
        $student->syncRoles([UserRole::Student->value]);

        $anatomy = $this->seedMedicineAnatomy($instructor, $admin, $student);

        $this->seedSubjectBundle(
            instructor: $instructor,
            admin: $admin,
            student: $student,
            title: 'الكيمياء الحيوية الطبية',
            description: 'مبادئ الكيمياء الحيوية لطلاب الطب',
            category: SubjectCategory::Medicine,
            assignments: [
                [
                    'title' => 'واجب: مراجعة الإنزيمات',
                    'due_date' => now()->addDays(5),
                    'submitted' => false,
                ],
            ],
            quizzes: [
                ['title' => 'اختبار الكيمياء الحيوية', 'completed' => false],
            ],
            grade: 78.0,
        );

        $this->seedSubjectBundle(
            instructor: $instructor,
            admin: $admin,
            student: $student,
            title: 'برمجة تطبيقات الجوال',
            description: 'تعلم بناء تطبيقات Flutter و Dart',
            category: SubjectCategory::It,
            withVideo: true,
            assignments: [
                [
                    'title' => 'تسليم واجب البرمجة',
                    'due_date' => now()->addDays(3),
                    'submitted' => false,
                ],
                [
                    'title' => 'مشروع واجهات المستخدم',
                    'due_date' => now()->addDays(10),
                    'submitted' => false,
                ],
            ],
            quizzes: [
                ['title' => 'اختبار Dart الأساسيات', 'completed' => false],
                ['title' => 'اختبار Widgets', 'completed' => true, 'score' => 82],
            ],
            grade: 91.0,
        );

        $this->seedSubjectBundle(
            instructor: $instructor,
            admin: $admin,
            student: $student,
            title: 'قواعد البيانات',
            description: 'SQL وتصميم قواعد البيانات الع relational',
            category: SubjectCategory::It,
            assignments: [
                [
                    'title' => 'واجب ER Diagram',
                    'due_date' => now()->addDays(6),
                    'submitted' => true,
                    'submission_grade' => 88,
                ],
            ],
            quizzes: [
                ['title' => 'اختبار SQL', 'completed' => true, 'score' => 76],
            ],
            grade: 84.5,
        );

        $this->seedSubjectBundle(
            instructor: $instructor,
            admin: $admin,
            student: $student,
            title: 'أمن المعلومات',
            description: 'مبادئ الحماية والتشفير',
            category: SubjectCategory::It,
            quizzes: [
                ['title' => 'اختبار منتصف الفصل', 'completed' => false],
            ],
        );

        $this->seedSubjectBundle(
            instructor: $instructor,
            admin: $admin,
            student: $student,
            title: 'رياضيات هندسية',
            description: 'تفاضل وتكامل للمهندسين',
            category: SubjectCategory::Engineering,
            assignments: [
                [
                    'title' => 'واجب التفاضل',
                    'due_date' => now()->addDays(4),
                    'submitted' => false,
                ],
            ],
            quizzes: [
                ['title' => 'اختبار رياضيات 1', 'completed' => false],
            ],
            grade: 73.0,
        );

        $this->seedSubjectBundle(
            instructor: $instructor,
            admin: $admin,
            student: $student,
            title: 'ميكانيكا المواد',
            description: 'دراسة الإجهاد والانفعال في المواد',
            category: SubjectCategory::Engineering,
            assignments: [
                [
                    'title' => 'تقرير مختبر المواد',
                    'due_date' => now()->addDays(8),
                    'submitted' => false,
                ],
            ],
            grade: 86.0,
        );

        $this->seedStudentNotifications($student, $anatomy);

        $mobileSubject = Subject::query()
            ->where('title', 'برمجة تطبيقات الجوال')
            ->first();

        $this->seedStudentAnnouncements($instructor, $anatomy, $mobileSubject);
    }

    private function seedMedicineAnatomy(User $instructor, User $admin, User $student): Subject
    {
        $subject = Subject::updateOrCreate(
            [
                'instructor_id' => $instructor->id,
                'title' => 'أساسيات التشريح',
            ],
            [
                'description' => 'مادة تجريبية لأساسيات التشريح',
                'category' => SubjectCategory::Medicine,
                'status' => ContentStatus::Active,
                'price' => 50,
            ]
        );

        $lesson1 = Lesson::updateOrCreate(
            ['subject_id' => $subject->id, 'title' => 'محاضرة 1'],
            ['order' => 1, 'status' => ContentStatus::Active]
        );

        $lesson2 = Lesson::updateOrCreate(
            ['subject_id' => $subject->id, 'title' => 'محاضرة 2'],
            ['order' => 2, 'status' => ContentStatus::Active]
        );

        Video::updateOrCreate(
            ['lesson_id' => $lesson1->id, 'title' => 'فيديو تجريبي'],
            [
                'storage_provider' => 'demo',
                'video_url' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                'original_file_name' => 'فيديو تجريبي (رابط خارجي)',
                'duration_seconds' => 15,
                'status' => VideoStatus::Ready,
            ]
        );

        LessonFile::updateOrCreate(
            ['lesson_id' => $lesson1->id, 'title' => 'ملف PDF تجريبي'],
            [
                'file_type' => FileType::Pdf,
                'file_url' => 'https://pdfobject.com/pdf/sample.pdf',
                'file_size' => 102_400,
            ]
        );

        $assignment1 = Assignment::updateOrCreate(
            [
                'subject_id' => $subject->id,
                'title' => 'واجب 1: مقدمة التشريح',
            ],
            [
                'lesson_id' => $lesson1->id,
                'description' => 'اكتب ملخصاً قصيراً عن محتوى المحاضرة الأولى.',
                'due_date' => now()->addDays(7),
                'status' => ContentStatus::Active,
            ]
        );

        AssignmentSubmission::updateOrCreate(
            [
                'assignment_id' => $assignment1->id,
                'student_id' => $student->id,
            ],
            [
                'answer_text' => 'ملخص تجريبي عن مقدمة التشريح وبنية جسم الإنسان.',
                'submitted_at' => now()->subDays(2),
                'grade' => 92.50,
            ]
        );

        Assignment::updateOrCreate(
            [
                'subject_id' => $subject->id,
                'title' => 'واجب 2: مراجعة عامة',
            ],
            [
                'lesson_id' => null,
                'description' => 'أجب عن الأسئلة التالية باختصار.',
                'due_date' => now()->addDays(2),
                'status' => ContentStatus::Active,
            ]
        );

        $quiz = Quiz::updateOrCreate(
            [
                'subject_id' => $subject->id,
                'title' => 'اختبار المحاضرة الأولى',
            ],
            [
                'lesson_id' => $lesson1->id,
                'description' => 'اختبار قصير لمراجعة محتوى المحاضرة الأولى.',
                'duration_minutes' => 10,
                'status' => ContentStatus::Active,
            ]
        );

        $question1 = QuizQuestion::updateOrCreate(
            [
                'quiz_id' => $quiz->id,
                'question_text' => 'ما هو تعريف التشريح؟',
            ],
            [
                'question_type' => QuestionType::Mcq,
                'points' => 1,
            ]
        );

        $this->seedMcqAnswers($question1, [
            ['text' => 'دراسة بنية جسم الإنسان', 'correct' => true],
            ['text' => 'دراسة وظائف الأعضاء', 'correct' => false],
            ['text' => 'دراسة الأمراض', 'correct' => false],
            ['text' => 'دراسة الأدوية', 'correct' => false],
        ]);

        $question2 = QuizQuestion::updateOrCreate(
            [
                'quiz_id' => $quiz->id,
                'question_text' => 'التشريح يدرس بنية جسم الإنسان.',
            ],
            [
                'question_type' => QuestionType::TrueFalse,
                'points' => 1,
            ]
        );

        $this->seedMcqAnswers($question2, [
            ['text' => 'صح', 'correct' => true],
            ['text' => 'خطأ', 'correct' => false],
        ]);

        QuizAttempt::updateOrCreate(
            [
                'quiz_id' => $quiz->id,
                'student_id' => $student->id,
            ],
            [
                'score' => 88,
                'started_at' => now()->subDays(3),
                'submitted_at' => now()->subDays(3)->addMinutes(8),
            ]
        );

        Grade::updateOrCreate(
            [
                'student_id' => $student->id,
                'subject_id' => $subject->id,
                'source_type' => GradeSourceType::Quiz,
                'source_id' => $quiz->id,
            ],
            ['grade' => 88.00]
        );

        Grade::updateOrCreate(
            [
                'student_id' => $student->id,
                'subject_id' => $subject->id,
                'source_type' => GradeSourceType::Assignment,
                'source_id' => $assignment1->id,
            ],
            [
                'grade' => 92.50,
                'notes' => 'أداء ممتاز في الواجب',
            ]
        );

        Grade::updateOrCreate(
            [
                'student_id' => $student->id,
                'subject_id' => $subject->id,
                'source_type' => GradeSourceType::Manual,
                'source_id' => null,
                'notes' => 'مشاركة فعّالة في المحاضرة',
            ],
            ['grade' => 85.00]
        );

        $this->enrollStudent($subject, $student, $admin);

        return $subject;
    }

    /**
     * @param  list<array{
     *     title: string,
     *     due_date?: Carbon,
     *     submitted?: bool,
     *     submission_grade?: float|int
     * }>  $assignments
     * @param  list<array{
     *     title: string,
     *     completed?: bool,
     *     score?: float|int
     * }>  $quizzes
     */
    private function seedSubjectBundle(
        User $instructor,
        User $admin,
        User $student,
        string $title,
        string $description,
        SubjectCategory $category,
        array $assignments = [],
        array $quizzes = [],
        ?float $grade = null,
        bool $withVideo = false,
    ): Subject {
        $subject = Subject::updateOrCreate(
            [
                'instructor_id' => $instructor->id,
                'title' => $title,
            ],
            [
                'description' => $description,
                'category' => $category,
                'status' => ContentStatus::Active,
                'price' => 40,
            ]
        );

        $lesson = Lesson::updateOrCreate(
            ['subject_id' => $subject->id, 'title' => 'المحاضرة 1'],
            ['order' => 1, 'status' => ContentStatus::Active]
        );

        if ($withVideo) {
            Video::updateOrCreate(
                ['lesson_id' => $lesson->id, 'title' => 'محاضرة مسجلة'],
                [
                    'storage_provider' => 'demo',
                    'video_url' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                    'original_file_name' => 'محاضرة مسجلة (رابط خارجي)',
                    'duration_seconds' => 20,
                    'status' => VideoStatus::Ready,
                ]
            );
        }

        foreach ($assignments as $assignmentData) {
            $assignment = Assignment::updateOrCreate(
                [
                    'subject_id' => $subject->id,
                    'title' => $assignmentData['title'],
                ],
                [
                    'lesson_id' => $lesson->id,
                    'description' => 'واجب تجريبي لاختبار التطبيق.',
                    'due_date' => $assignmentData['due_date'] ?? now()->addDays(7),
                    'status' => ContentStatus::Active,
                ]
            );

            if ($assignmentData['submitted'] ?? false) {
                AssignmentSubmission::updateOrCreate(
                    [
                        'assignment_id' => $assignment->id,
                        'student_id' => $student->id,
                    ],
                    [
                        'answer_text' => 'إجابة تجريبية مُسلّمة.',
                        'submitted_at' => now()->subDay(),
                        'grade' => $assignmentData['submission_grade'] ?? 85,
                    ]
                );
            }
        }

        foreach ($quizzes as $quizData) {
            $quiz = Quiz::updateOrCreate(
                [
                    'subject_id' => $subject->id,
                    'title' => $quizData['title'],
                ],
                [
                    'lesson_id' => $lesson->id,
                    'description' => 'اختبار تجريبي.',
                    'duration_minutes' => 15,
                    'status' => ContentStatus::Active,
                ]
            );

            $question = QuizQuestion::updateOrCreate(
                [
                    'quiz_id' => $quiz->id,
                    'question_text' => "سؤال تجريبي — {$quizData['title']}",
                ],
                [
                    'question_type' => QuestionType::TrueFalse,
                    'points' => 1,
                ]
            );

            $this->seedMcqAnswers($question, [
                ['text' => 'صح', 'correct' => true],
                ['text' => 'خطأ', 'correct' => false],
            ]);

            if ($quizData['completed'] ?? false) {
                QuizAttempt::updateOrCreate(
                    [
                        'quiz_id' => $quiz->id,
                        'student_id' => $student->id,
                    ],
                    [
                        'score' => $quizData['score'] ?? 80,
                        'started_at' => now()->subDays(2),
                        'submitted_at' => now()->subDays(2)->addMinutes(10),
                    ]
                );
            }
        }

        if ($grade !== null) {
            Grade::updateOrCreate(
                [
                    'student_id' => $student->id,
                    'subject_id' => $subject->id,
                    'source_type' => GradeSourceType::Manual,
                    'source_id' => null,
                    'notes' => "تقييم عام — {$title}",
                ],
                ['grade' => $grade]
            );
        }

        $this->enrollStudent($subject, $student, $admin);

        return $subject;
    }

    private function enrollStudent(Subject $subject, User $student, User $admin): void
    {
        SubjectStudent::updateOrCreate(
            [
                'subject_id' => $subject->id,
                'student_id' => $student->id,
            ],
            [
                'activated_by' => $admin->id,
                'payment_status' => PaymentStatus::Paid,
                'access_status' => AccessStatus::Active,
                'activated_at' => now()->subDays(30),
            ]
        );
    }

    private function seedStudentNotifications(User $student, Subject $subject): void
    {
        $assignment = Assignment::query()
            ->where('subject_id', $subject->id)
            ->where('title', 'واجب 2: مراجعة عامة')
            ->first();

        $quiz = Quiz::query()
            ->where('subject_id', $subject->id)
            ->where('title', 'اختبار المحاضرة الأولى')
            ->first();

        $notifications = [
            [
                'type' => 'subject_activated',
                'title' => 'تم تفعيل مادة جديدة',
                'body' => "تم تفعيل مادتك «{$subject->title}» بنجاح. يمكنك الآن الوصول إلى محتوى المادة.",
                'is_read' => false,
            ],
            [
                'type' => 'assignment_created',
                'title' => 'واجب جديد',
                'body' => $assignment
                    ? "تم إضافة واجب جديد: «{$assignment->title}». يرجى مراجعته وتسليمه في الوقت المحدد."
                    : 'تم إضافة واجب جديد. يرجى مراجعته من قسم الواجبات.',
                'is_read' => false,
            ],
            [
                'type' => 'quiz_created',
                'title' => 'اختبار جديد',
                'body' => $quiz
                    ? "تم إضافة اختبار جديد: «{$quiz->title}». يمكنك البدء من قسم الاختبارات."
                    : 'تم إضافة اختبار جديد في إحدى موادك.',
                'is_read' => false,
            ],
            [
                'type' => 'grade_published',
                'title' => 'درجة جديدة',
                'body' => 'تم إضافة درجة جديدة في مادة أساسيات التشريح. راجع قسم درجاتي للتفاصيل.',
                'is_read' => true,
            ],
            [
                'type' => 'announcement',
                'title' => 'إعلان عام',
                'body' => 'مرحباً بك في منصة RSHD التعليمية. نتمنى لك تجربة تعليمية ممتعة ومفيدة.',
                'is_read' => false,
            ],
            [
                'type' => 'custom',
                'title' => 'تذكير بتسليم واجب',
                'body' => 'لديك واجبات غير مسلّمة في مادة برمجة تطبيقات الجوال. لا تنسَ تسليمها قبل الموعد.',
                'is_read' => false,
            ],
            [
                'type' => 'quiz_created',
                'title' => 'اختبار متاح',
                'body' => 'اختبار منتصف الفصل متاح الآن في مادة أمن المعلومات.',
                'is_read' => true,
            ],
        ];

        foreach ($notifications as $notification) {
            AppNotification::updateOrCreate(
                [
                    'user_id' => $student->id,
                    'type' => $notification['type'],
                    'title' => $notification['title'],
                ],
                [
                    'body' => $notification['body'],
                    'is_read' => $notification['is_read'],
                ]
            );
        }
    }

    private function seedStudentAnnouncements(
        User $instructor,
        Subject $anatomySubject,
        ?Subject $mobileSubject,
    ): void {
        $welcomeImage = $this->seedAnnouncementImage(
            'announcements/welcome-rshd.png',
            base_path('../assets/images/rshd_logo.png'),
        );
        $lectureImage = $this->seedAnnouncementImage(
            'announcements/new-lecture.png',
            base_path('../assets/images/rshd_logo_no_bg.png'),
        );
        $examImage = $this->seedAnnouncementImage(
            'announcements/exam-reminder.png',
            base_path('../assets/images/rshd_logo.png'),
        );

        Announcement::updateOrCreate(
            ['title' => 'مرحباً بكم في منصة RSHD'],
            [
                'body' => 'نرحّب بكم في منصة RSHD التعليمية. نتمنى لكم تجربة تعليمية ممتعة ومثمرة طوال الفصل الدراسي.',
                'target_type' => AnnouncementTargetType::All,
                'type' => AnnouncementType::General,
                'instructor_id' => $instructor->id,
                'subject_id' => null,
                'image' => $welcomeImage,
            ]
        );

        if ($mobileSubject !== null) {
            Announcement::updateOrCreate(
                [
                    'title' => 'تم إضافة محاضرة جديدة',
                    'subject_id' => $mobileSubject->id,
                ],
                [
                    'body' => 'تم إضافة محاضرة جديدة في مادة برمجة تطبيقات الجوال. يرجى مراجعتها من قسم المواد.',
                    'target_type' => AnnouncementTargetType::Subject,
                    'type' => AnnouncementType::Subject,
                    'instructor_id' => $instructor->id,
                    'image' => $lectureImage,
                ]
            );
        }

        Announcement::updateOrCreate(
            ['title' => 'تذكير بموعد الاختبار'],
            [
                'body' => 'تذكير: يرجى الاستعداد لاختبار منتصف الفصل القادم والالتزام بالمواعيد المحددة.',
                'target_type' => AnnouncementTargetType::All,
                'type' => AnnouncementType::Important,
                'instructor_id' => $instructor->id,
                'subject_id' => null,
                'image' => $examImage,
            ]
        );
    }

    private function seedAnnouncementImage(string $storagePath, string $sourcePath): ?string
    {
        if (! File::exists($sourcePath)) {
            return null;
        }

        Storage::disk('public')->put(
            $storagePath,
            File::get($sourcePath),
        );

        return $storagePath;
    }

    /**
     * @param  list<array{text: string, correct: bool}>  $options
     */
    private function seedMcqAnswers(QuizQuestion $question, array $options): void
    {
        foreach ($options as $option) {
            QuizAnswer::updateOrCreate(
                [
                    'question_id' => $question->id,
                    'answer_text' => $option['text'],
                ],
                [
                    'is_correct' => $option['correct'],
                ]
            );
        }
    }
}
