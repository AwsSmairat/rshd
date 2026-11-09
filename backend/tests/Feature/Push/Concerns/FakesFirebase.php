<?php

namespace Tests\Feature\Push\Concerns;

use Illuminate\Support\Facades\Http;

trait FakesFirebase
{
    /**
     * A throwaway service account, signed with a key made for the test.
     */
    protected function configureFakeFirebase(): void
    {
        $key = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
        openssl_pkey_export($key, $pem);

        config([
            'services.firebase.project_id' => 'rshd-test',
            'services.firebase.credentials' => null,
            'services.firebase.credentials_json' => json_encode([
                'type' => 'service_account',
                'project_id' => 'rshd-test',
                'client_email' => 'push@rshd-test.iam.gserviceaccount.com',
                'private_key' => $pem,
                'token_uri' => 'https://oauth2.googleapis.com/token',
            ]),
        ]);
    }

    /**
     * @param  array<int, mixed>  $fcmResponses  one response per send, in order
     */
    protected function fakeFirebaseHttp(array $fcmResponses = []): void
    {
        $sequence = Http::sequence();
        foreach ($fcmResponses as $response) {
            $sequence->push(...$response);
        }
        $sequence->whenEmpty(Http::response(['name' => 'projects/rshd-test/messages/1'], 200));

        Http::fake([
            'oauth2.googleapis.com/*' => Http::response(['access_token' => 'test-access', 'expires_in' => 3600]),
            'fcm.googleapis.com/*' => $sequence,
        ]);
    }
}
