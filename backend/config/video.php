<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default video provider for new uploads
    |--------------------------------------------------------------------------
    |
    | local  -> private disk + signed Laravel stream endpoint
    | bunny  -> Bunny Stream + signed HLS CDN URLs
    |
    */
    'provider' => env('VIDEO_PROVIDER', 'local'),

    'signed_playback' => env('VIDEO_SIGNED_PLAYBACK', true),

    'playback_ttl' => (int) env('VIDEO_PLAYBACK_TTL', 600),

    'signing_key' => env('VIDEO_PLAYBACK_SIGNING_KEY'),

    'progress_position_tolerance_seconds' => (int) env('VIDEO_PROGRESS_TOLERANCE_SECONDS', 30),

    'secure_screen_enabled' => env('VIDEO_SECURE_SCREEN', false),

    'local' => [
        'disk' => env('VIDEO_LOCAL_DISK', 'lesson_videos'),
        'legacy_public_disk' => env('VIDEO_LEGACY_PUBLIC_DISK', 'public'),
    ],

    'bunny' => [
        'library_id' => env('BUNNY_STREAM_LIBRARY_ID'),
        'api_key' => env('BUNNY_STREAM_API_KEY'),
        'read_only_api_key' => env('BUNNY_STREAM_READ_ONLY_API_KEY'),
        'token_key' => env('BUNNY_STREAM_TOKEN_KEY'),
        'cdn_hostname' => env('BUNNY_STREAM_CDN_HOSTNAME'),
        'token_ip_binding' => env('BUNNY_STREAM_TOKEN_IP_BINDING', false),
        'upload_timeout' => (int) env('BUNNY_STREAM_UPLOAD_TIMEOUT', 3600),
        // embed = Bunny iframe player (works when CDN token auth is misconfigured)
        // cdn   = signed HLS direct to Pull Zone (requires correct BUNNY_STREAM_TOKEN_KEY)
        'playback_mode' => env('BUNNY_STREAM_PLAYBACK_MODE', 'embed'),
        'embed_token_key' => env('BUNNY_STREAM_EMBED_TOKEN_KEY'),
        // Serve staged local file when Bunny CDN is blocked/misconfigured.
        'local_fallback' => env('BUNNY_STREAM_LOCAL_FALLBACK', env('APP_ENV') === 'local'),
    ],

];
