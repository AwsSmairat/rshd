<?php

namespace App\Http\Resources;

use App\Http\Resources\StudentDeviceResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role?->value,
            'status' => $this->status?->value,
            'email_verified_at' => $this->email_verified_at,
            'is_email_verified' => $this->email_verified_at !== null,
            'password_set_at' => $this->password_set_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'terms_accepted_version' => $this->terms_accepted_version,
            'terms_accepted_at' => $this->terms_accepted_at,
            'active_device' => $this->when(
                $this->relationLoaded('activeStudentDevice'),
                fn () => $this->activeStudentDevice
                    ? StudentDeviceResource::make($this->activeStudentDevice)
                    : null,
            ),
        ];
    }
}
