<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class SendStudentHelpMessageRequest extends FormRequest
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
        return [
            'subject_id' => ['required', 'integer', 'exists:subjects,id'],
            'message' => ['required', 'string', 'min:3', 'max:2000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'subject_id.required' => 'يرجى تحديد المادة.',
            'subject_id.exists' => 'المادة المحددة غير موجودة.',
            'message.required' => 'يرجى كتابة رسالتك.',
            'message.min' => 'يجب أن تكون الرسالة 3 أحرف على الأقل.',
            'message.max' => 'يجب ألا تتجاوز الرسالة 2000 حرف.',
        ];
    }
}
