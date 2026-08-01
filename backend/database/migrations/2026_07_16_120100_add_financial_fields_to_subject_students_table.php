<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('subject_students', function (Blueprint $table) {
            $table->decimal('sale_price', 10, 2)->nullable()->after('payment_status');
            $table->timestamp('paid_at')->nullable()->after('sale_price');
        });
    }

    public function down(): void
    {
        Schema::table('subject_students', function (Blueprint $table) {
            $table->dropColumn(['sale_price', 'paid_at']);
        });
    }
};
