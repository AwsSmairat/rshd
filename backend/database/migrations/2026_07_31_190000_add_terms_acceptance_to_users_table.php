<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('terms_accepted_version', 32)->nullable()->after('preferences');
            $table->timestamp('terms_accepted_at')->nullable()->after('terms_accepted_version');
            $table->string('terms_accepted_platform', 64)->nullable()->after('terms_accepted_at');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'terms_accepted_version',
                'terms_accepted_at',
                'terms_accepted_platform',
            ]);
        });
    }
};
