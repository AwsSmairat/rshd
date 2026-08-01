<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('videos', function (Blueprint $table) {
            $table->string('video_path')->nullable()->after('video_url');
            $table->string('original_file_name')->nullable()->after('video_path');
            $table->unsignedBigInteger('file_size')->nullable()->after('original_file_name');
            $table->string('file_mime_type')->nullable()->after('file_size');
        });
    }

    public function down(): void
    {
        Schema::table('videos', function (Blueprint $table) {
            $table->dropColumn([
                'video_path',
                'original_file_name',
                'file_size',
                'file_mime_type',
            ]);
        });
    }
};
