<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\GradeResource;
use App\Models\Grade;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GradeController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Grade::class);

        $user = $request->user();

        if ($user->isStudent()) {
            $grades = $user->grades()->with('subject')->latest()->get();
        } elseif ($user->isInstructor()) {
            $grades = Grade::query()
                ->whereHas('subject', fn ($query) => $query->where('instructor_id', $user->id))
                ->with(['subject', 'student'])
                ->get();
        } else {
            $grades = Grade::query()->with(['subject', 'student'])->get();
        }

        return $this->successResourceList(GradeResource::collection($grades));
    }
}
