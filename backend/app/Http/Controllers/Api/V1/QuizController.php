<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\GradeSourceType;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\SubmitQuizRequest;
use App\Http\Resources\QuizAttemptResource;
use App\Http\Resources\QuizResource;
use App\Models\Grade;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Models\QuizAttemptAnswer;
use App\Services\PlatformNotificationService;
use App\Services\PlatformSettingsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QuizController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Quiz::class);

        $user = $request->user();

        if ($user->isStudent()) {
            $subjectIds = $user->enrolledSubjects()
                ->wherePivot('payment_status', PaymentStatus::Paid)
                ->wherePivot('access_status', AccessStatus::Active)
                ->pluck('subjects.id');

            $quizzes = Quiz::query()
                ->whereIn('subject_id', $subjectIds)
                ->where('status', ContentStatus::Active)
                ->withCount('questions')
                ->with([
                    'subject',
                    'lesson',
                    'attempts' => fn ($query) => $query
                        ->where('student_id', $user->id)
                        ->orderByDesc('started_at')
                        ->limit(1),
                ])
                ->get();
        } elseif ($user->isInstructor()) {
            $quizzes = Quiz::query()
                ->whereHas('subject', fn ($query) => $query->where('instructor_id', $user->id))
                ->with(['subject', 'lesson'])
                ->get();
        } else {
            $quizzes = Quiz::query()
                ->with(['subject', 'lesson'])
                ->get();
        }

        return $this->successResourceList(QuizResource::collection($quizzes));
    }

    public function start(
        Request $request,
        Quiz $quiz,
        PlatformSettingsService $settings,
    ): JsonResponse {
        $this->authorize('start', $quiz);

        $studentId = $request->user()->id;

        $attempt = DB::transaction(function () use ($quiz, $studentId, $settings) {
            $attempt = QuizAttempt::query()
                ->where('quiz_id', $quiz->id)
                ->where('student_id', $studentId)
                ->whereNull('submitted_at')
                ->lockForUpdate()
                ->latest('started_at')
                ->first();

            if (! $attempt) {
                $hasSubmittedAttempt = QuizAttempt::query()
                    ->where('quiz_id', $quiz->id)
                    ->where('student_id', $studentId)
                    ->whereNotNull('submitted_at')
                    ->lockForUpdate()
                    ->exists();

                if ($hasSubmittedAttempt && ! $settings->enabled('allow_quiz_retake', 'students')) {
                    return null;
                }

                $attempt = QuizAttempt::query()->create([
                    'quiz_id' => $quiz->id,
                    'student_id' => $studentId,
                    'started_at' => now(),
                ]);
            }

            return $attempt;
        });

        if ($attempt === null) {
            return $this->errorResponse('إعادة الاختبار غير مسموحة.', 422);
        }

        $quiz->load(['questions.answers']);

        return $this->successResponse([
            'attempt_id' => $attempt->id,
            'quiz' => (new QuizResource($quiz, hideCorrectAnswers: true))->resolve($request),
        ], 'تم بدء الاختبار بنجاح.');
    }

    public function submit(
        SubmitQuizRequest $request,
        Quiz $quiz,
        PlatformSettingsService $settings,
        PlatformNotificationService $notifications,
    ): JsonResponse {
        $this->authorize('submit', $quiz);

        $user = $request->user();

        $quiz->load(['questions.answers']);

        // One answer per question: the request rejects repeats, and only the
        // first answer for a question is kept should one slip through.
        $answers = collect($request->validated('answers'))
            ->unique('question_id')
            ->values();

        $result = DB::transaction(function () use ($quiz, $answers, $user) {
            // Locked, so the same attempt cannot be submitted twice at once.
            $attempt = QuizAttempt::query()
                ->where('quiz_id', $quiz->id)
                ->where('student_id', $user->id)
                ->whereNull('submitted_at')
                ->latest('started_at')
                ->lockForUpdate()
                ->first();

            if ($attempt === null) {
                return null;
            }

            // Past the time limit the attempt closes without its answers.
            $timedOut = $this->isPastTimeLimit($quiz, $attempt);

            $totalPoints = $quiz->questions->sum('points');
            $earnedPoints = 0;

            foreach ($timedOut ? [] : $answers as $answerData) {
                $question = $quiz->questions->firstWhere('id', $answerData['question_id']);

                if ($question === null) {
                    continue;
                }

                $isCorrect = false;

                if (! empty($answerData['answer_id'])) {
                    $selectedAnswer = $question->answers->firstWhere('id', $answerData['answer_id']);
                    $isCorrect = $selectedAnswer !== null && $selectedAnswer->is_correct;
                }

                QuizAttemptAnswer::query()->create([
                    'quiz_attempt_id' => $attempt->id,
                    'question_id' => $question->id,
                    'answer_id' => $answerData['answer_id'] ?? null,
                    'answer_text' => $answerData['answer_text'] ?? null,
                    'is_correct' => $isCorrect,
                ]);

                if ($isCorrect) {
                    $earnedPoints += $question->points;
                }
            }

            $score = $totalPoints > 0
                ? round(min(1, $earnedPoints / $totalPoints) * 100, 2)
                : 0.0;

            $attempt->update([
                'score' => $score,
                'submitted_at' => now(),
            ]);

            $grade = Grade::query()->updateOrCreate(
                [
                    'student_id' => $user->id,
                    'subject_id' => $quiz->subject_id,
                    'source_type' => GradeSourceType::Quiz,
                    'source_id' => $quiz->id,
                ],
                [
                    'grade' => $score,
                ],
            );

            return [
                'attempt_id' => $attempt->id,
                'grade_id' => $grade->id,
                'score' => $score,
                'timed_out' => $timedOut,
                'questions_count' => $quiz->questions->count(),
            ];
        });

        if ($result === null) {
            return $this->errorResponse('لا توجد محاولة مفتوحة لهذا الاختبار.', 404);
        }

        if ($result['timed_out']) {
            return $this->errorResponse('انتهى وقت الاختبار، ولم تُحتسب الإجابات المرسلة بعده.', 422);
        }

        $attempt = QuizAttempt::query()->findOrFail($result['attempt_id']);

        $notifications->notifyUser(
            user: $user,
            title: 'تم نشر درجة الاختبار',
            body: 'درجتك في اختبار «'.$quiz->title.'»: '.$result['score'].'%',
            type: 'grade_published',
            settingKey: 'notify_student_grade_published',
            data: [
                'grade_id' => $result['grade_id'],
                'quiz_id' => $quiz->id,
                'subject_id' => $quiz->subject_id,
            ],
        );

        $payload = array_merge(
            QuizAttemptResource::make($attempt)->resolve($request),
            ['questions_count' => $result['questions_count']],
        );

        if ($settings->enabled('show_quiz_correct_answers', 'students')) {
            $quiz->load(['questions.answers']);
            $payload['quiz'] = (new QuizResource($quiz, hideCorrectAnswers: false))->resolve($request);
        }

        return $this->successResponse(
            $payload,
            'تم تسليم الاختبار بنجاح.',
        );
    }

    /** Network slack allowed after the time limit before answers are refused. */
    private const TIME_LIMIT_GRACE_SECONDS = 120;

    private function isPastTimeLimit(Quiz $quiz, QuizAttempt $attempt): bool
    {
        $minutes = (int) $quiz->duration_minutes;

        if ($minutes <= 0 || $attempt->started_at === null) {
            return false;
        }

        return now()->greaterThan(
            $attempt->started_at->copy()
                ->addMinutes($minutes)
                ->addSeconds(self::TIME_LIMIT_GRACE_SECONDS),
        );
    }
}
