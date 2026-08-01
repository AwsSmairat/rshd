<?php

namespace App\Http\Requests\Api\V1;

use App\Services\PlatformSettingsService;
use Illuminate\Foundation\Http\FormRequest;

class GoogleAuthRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $settings = app(PlatformSettingsService::class);

        return [
            'id_token' => ['required', 'string'],
            'device_id' => $settings->deviceIdRules(),
            'device_name' => ['nullable', 'string', 'max:255'],
            'platform' => ['nullable', 'string', 'max:50'],
        ];
    }
}
