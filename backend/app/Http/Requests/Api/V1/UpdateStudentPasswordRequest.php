<?php

namespace App\Http\Requests\Api\V1;

use App\Services\PlatformSettingsService;
use Illuminate\Foundation\Http\FormRequest;

class UpdateStudentPasswordRequest extends FormRequest
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
            'current_password' => ['required', 'string'],
            'password' => app(PlatformSettingsService::class)->passwordRules(confirmed: true),
        ];
    }
}
