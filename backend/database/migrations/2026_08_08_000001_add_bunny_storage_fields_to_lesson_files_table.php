<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('lesson_files', function (Blueprint $table) {
            $table->string('storage_provider')->nullable()->after('file_mime_type');
            $table->string('storage_disk')->nullable()->after('storage_provider');
            $table->string('external_path')->nullable()->after('storage_disk');
            $table->string('storage_status')->nullable()->after('external_path');
            $table->timestamp('uploaded_at')->nullable()->after('storage_status');
        });
    }

    public function down(): void
    {
        Schema::table('lesson_files', function (Blueprint $table) {
            $table->dropColumn([
                'storage_provider',
                'storage_disk',
                'external_path',
                'storage_status',
                'uploaded_at',
            ]);
        });
    }
};
