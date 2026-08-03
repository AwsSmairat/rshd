<?php

namespace App\Services;

use App\Enums\ContentStatus;
use App\Filament\Resources\AssignmentResource;
use App\Filament\Resources\LessonResource;
use App\Filament\Resources\QuizResource;
use App\Models\Assignment;
use App\Models\Lesson;
use App\Models\Quiz;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class InstructorCalendarService
{
    /**
     * @return Collection<int, array{
     *     date: Carbon,
     *     date_key: string,
     *     label: string,
     *     day_name: string,
     *     is_today: bool,
     *     events_count: int,
     *     events: list<array{
     *         title: string,
     *         type: string,
     *         type_label: string,
     *         subject_title: string|null,
     *         time: string|null,
     *         url: string|null
     *     }>
     * }>
     */
    public function weekFor(User $instructor): Collection
    {
        $subjectIds = $instructor->subjectsTeaching()->pluck('id');
        $start = now()->startOfWeek(Carbon::SATURDAY);
        $days = collect();

        for ($i = 0; $i < 7; $i++) {
            $date = $start->copy()->addDays($i);
            $events = $subjectIds->isEmpty()
                ? []
                : $this->eventsForDate($instructor, $subjectIds, $date);

            $days->push([
                'date' => $date,
                'date_key' => $date->toDateString(),
                'label' => $date->locale('ar')->translatedFormat('d M'),
                'day_name' => $date->locale('ar')->translatedFormat('D'),
                'is_today' => $date->isToday(),
                'events_count' => count($events),
                'events' => $events,
            ]);
        }

        return $days;
    }

    /**
     * @param  Collection<int, int>|\Illuminate\Support\Collection  $subjectIds
     * @return list<array{
     *     title: string,
     *     type: string,
     *     type_label: string,
     *     subject_title: string|null,
     *     time: string|null,
     *     url: string|null
     * }>
     */
    protected function eventsForDate(User $instructor, $subjectIds, Carbon $date): array
    {
        $subjectIds = collect($subjectIds);
        $events = [];

        Assignment::query()
            ->with('subject:id,title')
            ->whereIn('subject_id', $subjectIds)
            ->whereDate('due_date', $date)
            ->orderBy('due_date')
            ->get()
            ->each(function (Assignment $assignment) use (&$events): void {
                $events[] = [
                    'title' => $assignment->title,
                    'type' => 'assignment',
                    'type_label' => 'موعد تسليم واجب',
                    'subject_title' => $assignment->subject?->title,
                    'time' => $assignment->due_date?->timezone(config('app.timezone'))->format('H:i'),
                    'url' => AssignmentResource::getUrl('edit', ['record' => $assignment->id]),
                ];
            });

        Quiz::query()
            ->with('subject:id,title')
            ->whereIn('subject_id', $subjectIds)
            ->where('status', ContentStatus::Active)
            ->whereDate('created_at', $date)
            ->orderBy('created_at')
            ->get()
            ->each(function (Quiz $quiz) use (&$events): void {
                $events[] = [
                    'title' => $quiz->title,
                    'type' => 'quiz',
                    'type_label' => 'اختبار',
                    'subject_title' => $quiz->subject?->title,
                    'time' => $quiz->created_at?->timezone(config('app.timezone'))->format('H:i'),
                    'url' => QuizResource::getUrl('edit', ['record' => $quiz->id]),
                ];
            });

        Lesson::query()
            ->with('subject:id,title')
            ->whereIn('subject_id', $subjectIds)
            ->whereDate('created_at', $date)
            ->orderBy('created_at')
            ->get()
            ->each(function (Lesson $lesson) use (&$events): void {
                $events[] = [
                    'title' => $lesson->title,
                    'type' => 'lesson',
                    'type_label' => 'جزء/درس',
                    'subject_title' => $lesson->subject?->title,
                    'time' => $lesson->created_at?->timezone(config('app.timezone'))->format('H:i'),
                    'url' => LessonResource::getUrl('edit', ['record' => $lesson->id]),
                ];
            });

        usort($events, function (array $a, array $b): int {
            return strcmp($a['time'] ?? '99:99', $b['time'] ?? '99:99');
        });

        return $events;
    }
}
