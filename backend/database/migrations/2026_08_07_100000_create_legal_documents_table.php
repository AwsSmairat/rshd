<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('legal_documents', function (Blueprint $table) {
            $table->id();
            $table->string('type', 64);
            $table->string('title');
            $table->string('subtitle')->nullable();
            $table->string('summary')->nullable();
            $table->json('sections');
            $table->string('version', 32);
            $table->string('language', 8)->default('ar');
            $table->string('status', 32)->default('draft');
            $table->boolean('requires_acceptance')->default(false);
            $table->timestamp('published_at')->nullable();
            $table->timestamp('effective_at')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['type', 'language', 'status']);
            $table->unique(['type', 'language', 'version']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('legal_documents');
    }
};
