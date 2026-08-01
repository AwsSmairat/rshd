<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class UpdateVideoProgressRequest extends FormRequest
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
            'watched_seconds' => ['required', 'integer', 'min:0'],
            'current_position' => ['required', 'integer', 'min:0'],
            'replay_count' => ['sometimes', 'integer', 'min:0'],
            'completion_percentage' => ['sometimes', 'integer', 'min:0', 'max:100'],
        ];
    }
}
