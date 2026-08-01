<?php

namespace App\Http\Requests\Api\V1;

use App\Services\PlatformSettingsService;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return app(PlatformSettingsService::class)->studentRegistrationEnabled();
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $settings = app(PlatformSettingsService::class);

        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'phone' => $settings->enabled('phone_required', 'registration')
                ? ['required', 'string', 'max:50']
                : ['nullable', 'string', 'max:50'],
            'password' => $settings->passwordRules(confirmed: true),
            'terms_accepted' => $settings->enabled('terms_required', 'registration')
                ? ['accepted']
                : ['nullable'],
            'device_id' => $settings->deviceIdRules(),
            'device_name' => ['nullable', 'string', 'max:255'],
            'platform' => ['nullable', 'string', 'max:50'],
        ];
    }

    protected function failedAuthorization(): void
    {
        abort(403, 'التسجيل الذاتي للطلاب غير مفعّل حالياً.');
    }

    public function withValidator(Validator $validator): void
    {
        $validator->sometimes('terms_accepted', ['accepted'], function (): bool {
            return app(PlatformSettingsService::class)->enabled('terms_required', 'registration');
        });
    }
}
