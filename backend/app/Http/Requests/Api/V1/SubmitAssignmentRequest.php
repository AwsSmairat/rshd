<?php

namespace App\Http\Requests\Api\V1;

use App\Services\PlatformSettingsService;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class SubmitAssignmentRequest extends FormRequest
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
            'answer_text' => ['nullable', 'string', 'max:2000'],
            'file' => $settings->assignmentFileRules(),
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $answerText = trim((string) $this->input('answer_text', ''));
            $hasFile = $this->hasFile('file');

            if ($answerText === '' && ! $hasFile) {
                $validator->errors()->add(
                    'answer_text',
                    'يرجى كتابة إجابة أو رفع ملف الحل.',
                );
            }
        });
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        $maxMb = app(PlatformSettingsService::class)->integer('assignment_max_file_size_mb', 10, 'students');

        return [
            'file.max' => "حجم الملف يجب ألا يتجاوز {$maxMb}MB.",
            'file.mimes' => 'نوع الملف غير مدعوم.',
        ];
    }
}
