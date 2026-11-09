<?php

namespace App\Http\Requests\Api\V1;

use App\Models\PushDeviceToken;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RegisterPushTokenRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            // FCM tokens are opaque; they run to a few hundred characters.
            'token' => ['required', 'string', 'min:20', 'max:4096', 'regex:/^[A-Za-z0-9_:\-\.]+$/'],
            'platform' => ['required', 'string', Rule::in([PushDeviceToken::PLATFORM_IOS, PushDeviceToken::PLATFORM_ANDROID])],
            'app_version' => ['nullable', 'string', 'max:32'],
        ];
    }
}
