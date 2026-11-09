<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'resend' => [
        'key' => env('RESEND_KEY'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'google' => [
        'client_ids' => array_values(array_filter(array_map(
            static fn (string $id): string => trim($id),
            explode(',', (string) env('GOOGLE_CLIENT_IDS', '')),
        ))),
    ],

    'apple' => [
        'client_ids' => array_values(array_filter(array_map(
            static fn (string $id): string => trim($id),
            explode(',', (string) env('APPLE_CLIENT_IDS', 'com.example.rshd')),
        ))),
    ],

    /*
     * Firebase Cloud Messaging (HTTP v1). The service account JSON lives on
     * the server only, outside git: either a file path or the JSON itself
     * (base64 allowed) in FIREBASE_CREDENTIALS_JSON.
     */
    'firebase' => [
        'project_id' => env('FIREBASE_PROJECT_ID', 'rshd-academy'),
        'credentials' => env('FIREBASE_CREDENTIALS', storage_path('app/private/firebase/service-account.json')),
        'credentials_json' => env('FIREBASE_CREDENTIALS_JSON'),
        'push_queue' => env('PUSH_QUEUE', 'default'),
    ],

];
