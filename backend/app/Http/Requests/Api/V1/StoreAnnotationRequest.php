<?php

namespace App\Http\Requests\Api\V1;

use Closure;
use Illuminate\Foundation\Http\FormRequest;

class StoreAnnotationRequest extends FormRequest
{
    /**
     * Annotations are stored verbatim in a JSON column, so an unbounded payload
     * would let any student exhaust memory and bloat the table.
     */
    private const MAX_ENCODED_BYTES = 2 * 1024 * 1024;

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
            'annotation_json' => [
                'required',
                'array',
                function (string $attribute, mixed $value, Closure $fail): void {
                    $encoded = json_encode($value);

                    if ($encoded === false) {
                        $fail('تعذر قراءة بيانات الملاحظات.');

                        return;
                    }

                    if (strlen($encoded) > self::MAX_ENCODED_BYTES) {
                        $fail('حجم الملاحظات كبير جداً، يرجى تقليل عدد التعليقات.');
                    }
                },
            ],
        ];
    }
}
