<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('platform_settings', function (Blueprint $table) {
            $table->string('group')->default('platform')->after('id');
            $table->string('type')->default('string')->after('value');
            $table->boolean('is_public')->default(false)->after('type');
        });

        $legacyMap = [
            'platform_name' => ['group' => 'platform', 'key' => 'platform_name', 'is_public' => true],
            'platform_tagline' => ['group' => 'platform', 'key' => 'platform_subtitle', 'is_public' => true],
            'support_email' => ['group' => 'platform', 'key' => 'support_email', 'is_public' => true],
            'support_phone' => ['group' => 'platform', 'key' => 'support_phone', 'is_public' => true],
            'currency_label' => ['group' => 'platform', 'key' => 'currency_symbol', 'is_public' => true],
            'activation_note' => ['group' => 'platform', 'key' => 'activation_note', 'is_public' => true],
        ];

        foreach (DB::table('platform_settings')->get() as $row) {
            $mapping = $legacyMap[$row->key] ?? ['group' => 'platform', 'key' => $row->key, 'is_public' => false];

            DB::table('platform_settings')
                ->where('id', $row->id)
                ->update([
                    'group' => $mapping['group'],
                    'key' => $mapping['key'],
                    'is_public' => $mapping['is_public'],
                    'type' => 'string',
                ]);
        }

        Schema::table('platform_settings', function (Blueprint $table) {
            $table->dropUnique(['key']);
            $table->unique(['group', 'key']);
        });
    }

    public function down(): void
    {
        Schema::table('platform_settings', function (Blueprint $table) {
            $table->dropUnique(['group', 'key']);
            $table->unique('key');
            $table->dropColumn(['group', 'type', 'is_public']);
        });
    }
};
