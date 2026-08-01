<?php

namespace App\Services;

use App\Enums\AccessStatus;
use App\Enums\AnnouncementTargetType;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Models\Announcement;
use App\Models\User;
use Illuminate\Support\Collection;

class AnnouncementService
{
    public function __construct(
        protected PlatformNotificationService $notifications,
    ) {}

    public function notifyAffectedStudents(Announcement $announcement): void
    {
        $announcement->loadMissing('subject');

        $students = $this->affectedStudents($announcement);

        foreach ($students as $student) {
            $subjectSuffix = $announcement->subject !== null
                ? ' — '.$announcement->subject->title
                : '';

            $this->notifications->notifyUser(
                user: $student,
                title: 'إعلان جديد',
                body: '«'.$announcement->title.'»'.$subjectSuffix.'.',
                type: 'announcement',
                settingKey: 'notify_student_announcement_published',
                data: [
                    'announcement_id' => $announcement->id,
                    'subject_id' => $announcement->subject_id,
                ],
            );
        }
    }

    /**
     * @return Collection<int, User>
     */
    protected function affectedStudents(Announcement $announcement): Collection
    {
        return match ($announcement->target_type) {
            AnnouncementTargetType::All => User::query()
                ->where('role', UserRole::Student)
                ->get(),
            AnnouncementTargetType::Subject => $announcement->subject
                ?->students()
                ->wherePivot('payment_status', PaymentStatus::Paid)
                ->wherePivot('access_status', AccessStatus::Active)
                ->get() ?? collect(),
            default => collect(),
        };
    }
}
