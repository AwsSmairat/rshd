<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class UpdateStudentPreferencesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isStudent() ?? false;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'notify_lessons' => ['sometimes', 'boolean'],
            'notify_assignments' => ['sometimes', 'boolean'],
            'notify_assignment_reminders' => ['sometimes', 'boolean'],
            'notify_quizzes' => ['sometimes', 'boolean'],
            'notify_quiz_reminders' => ['sometimes', 'boolean'],
            'notify_grades' => ['sometimes', 'boolean'],
            'notify_messages' => ['sometimes', 'boolean'],
            'notify_announcements' => ['sometimes', 'boolean'],
            'notify_platform_updates' => ['sometimes', 'boolean'],
            'notification_sound' => ['sometimes', 'boolean'],
            'notification_vibration' => ['sometimes', 'boolean'],
            'language' => ['sometimes', 'string', 'in:ar,en'],
            'theme' => ['sometimes', 'string', 'in:light,dark,system'],
            'font_size' => ['sometimes', 'string', 'in:small,medium,large'],
            'downloads_wifi_only' => ['sometimes', 'boolean'],
            'auto_play_video' => ['sometimes', 'boolean'],
            'default_video_quality' => ['sometimes', 'string', 'in:auto,low,medium,high'],
            'save_watch_position' => ['sometimes', 'boolean'],
            'timezone' => ['sometimes', 'string', 'max:64'],
            'profile_visibility' => ['sometimes', 'string', 'in:everyone,teachers_only,private'],
            'messaging_permission' => ['sometimes', 'string', 'in:everyone,teachers_only,nobody'],
            'show_activity_status' => ['sometimes', 'boolean'],
            'allow_profile_photo_use' => ['sometimes', 'boolean'],
            'two_factor_enabled' => ['sometimes', 'boolean'],
        ];
    }
}
