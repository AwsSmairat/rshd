<?php

namespace Tests\Unit;

use App\Support\SensitiveDataRedactor;
use PHPUnit\Framework\TestCase;

class SensitiveDataRedactorTest extends TestCase
{
    public function test_redacts_bearer_tokens_in_strings(): void
    {
        $input = 'Authorization: Bearer abc.def.ghi failed';

        $this->assertStringContainsString('[REDACTED]', SensitiveDataRedactor::redactString($input));
        $this->assertStringNotContainsString('abc.def.ghi', SensitiveDataRedactor::redactString($input));
    }

    public function test_redacts_signed_url_query_parameters(): void
    {
        $url = 'https://cdn.example.com/file.pdf?token=secret&expires=123';

        $redacted = SensitiveDataRedactor::redactString($url);

        $this->assertStringContainsString('token=[REDACTED]', $redacted);
        $this->assertStringNotContainsString('secret', $redacted);
    }
}
