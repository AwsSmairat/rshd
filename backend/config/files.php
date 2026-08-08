<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Lesson files / PDF storage (Bunny Edge Storage)
    |--------------------------------------------------------------------------
    |
    | Storage API uses the storage zone password (AccessKey header) against the
    | regional storage hostname — NOT the Pull Zone CDN hostname.
    |
    | Find the storage hostname in Bunny → Storage Zone → FTP & API Access.
    |
    */
    'bunny' => [
        'token_key' => env('BUNNY_FILES_TOKEN_KEY'),
        'cdn_hostname' => env('BUNNY_FILES_CDN_HOSTNAME'),
        'storage_zone' => env('BUNNY_FILES_STORAGE_ZONE'),
        'storage_password' => env('BUNNY_FILES_STORAGE_PASSWORD'),
        // e.g. storage.bunnycdn.com, ny.storage.bunnycdn.com (region-specific)
        'storage_hostname' => env('BUNNY_FILES_STORAGE_HOSTNAME'),
    ],

    'signed_download' => env('FILES_SIGNED_DOWNLOAD', true),

    'download_ttl' => (int) env('BUNNY_FILES_DOWNLOAD_TTL', 600),

    'local_disk' => env('FILES_LOCAL_DISK', 'lesson_files'),

];
