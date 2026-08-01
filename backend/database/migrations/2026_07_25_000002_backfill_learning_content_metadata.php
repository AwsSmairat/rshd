<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('lessons')
            ->where('order', '<', 1)
            ->update(['order' => 1]);

        $videos = DB::table('videos')
            ->whereNull('original_file_name')
            ->get(['id', 'video_path', 'video_url', 'title']);

        foreach ($videos as $video) {
            $path = is_string($video->video_path) ? trim($video->video_path) : '';
            $name = $path !== ''
                ? basename($path)
                : (is_string($video->title) && $video->title !== '' ? $video->title : 'فيديو خارجي');

            DB::table('videos')
                ->where('id', $video->id)
                ->update(['original_file_name' => $name]);
        }
    }

    public function down(): void
    {
        // Non-destructive data backfill.
    }
};
