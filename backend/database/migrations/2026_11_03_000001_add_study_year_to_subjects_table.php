<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Study year (1–6) for medicine subjects, so the app can group them by
     * year. Nullable: other categories have no year, and existing subjects
     * stay as they are until an admin sets one.
     */
    public function up(): void
    {
        Schema::table('subjects', function (Blueprint $table) {
            $table->unsignedTinyInteger('study_year')->nullable()->after('category');
        });
    }

    public function down(): void
    {
        Schema::table('subjects', function (Blueprint $table) {
            $table->dropColumn('study_year');
        });
    }
};
