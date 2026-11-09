<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Firebase Cloud Messaging tokens, one per app install.
 *
 * Each token is bound to the Sanctum session it was registered with, so a
 * token disappears the moment that session ends (sign out, sign out of every
 * device, device reset, block, password change, account deletion). A phone
 * can therefore never keep receiving a previous account's notifications.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('push_device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('personal_access_token_id')
                ->constrained('personal_access_tokens')
                ->cascadeOnDelete();
            $table->char('token_hash', 64)->unique();
            $table->text('token');
            $table->string('platform', 16);
            $table->string('device_id', 200)->nullable();
            $table->string('app_version', 32)->nullable();
            $table->timestamp('last_registered_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'platform']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('push_device_tokens');
    }
};
