<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('assignment_submissions', function (Blueprint $table) {
            $table->string('file_path')->nullable()->after('file_url');
            $table->string('original_file_name')->nullable()->after('file_path');
            $table->unsignedBigInteger('file_size')->nullable()->after('original_file_name');
            $table->string('file_mime_type')->nullable()->after('file_size');
        });
    }

    public function down(): void
    {
        Schema::table('assignment_submissions', function (Blueprint $table) {
            $table->dropColumn([
                'file_path',
                'original_file_name',
                'file_size',
                'file_mime_type',
            ]);
        });
    }
};
