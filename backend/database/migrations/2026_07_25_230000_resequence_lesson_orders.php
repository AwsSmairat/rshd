<?php

use App\Models\Lesson;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $subjectIds = DB::table('lessons')
            ->distinct()
            ->orderBy('subject_id')
            ->pluck('subject_id');

        foreach ($subjectIds as $subjectId) {
            Lesson::resequenceForSubject((int) $subjectId);
        }
    }

    public function down(): void
    {
        // Irreversible data normalization.
    }
};
