<?php

namespace Tests\Unit;

use App\Services\Bunny\BunnyCdnTokenSigner;
use InvalidArgumentException;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class BunnyCdnTokenSignerTest extends TestCase
{
    private BunnyCdnTokenSigner $signer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->signer = new BunnyCdnTokenSigner;
    }

    public function test_matches_official_plain_vector(): void
    {
        $signed = $this->signer->signUrl(
            url: 'https://token-tester.b-cdn.net/300kb.jpg',
            securityKey: 'SecurityKey',
            expiresAt: 1_598_024_587,
        );

        $this->assertSame(
            'HS256-o10JRWlsAItyAsdKS6jJKjabHN4FrFsplDHPV1idcX4',
            $this->extractToken($signed),
        );
    }

    public function test_matches_official_path_only_vector(): void
    {
        $signed = $this->signer->signUrl(
            url: 'https://token-tester.b-cdn.net/abc/300kb.jpg',
            securityKey: 'SecurityKey',
            expiresAt: 1_598_024_587,
            pathAllowed: '/abc',
        );

        $this->assertSame(
            'HS256-uVZvT3SbEoVKYJyDJgbcsDmSFf73cv-uNUVaJiKWpbQ',
            $this->extractToken($signed),
        );
    }

    public function test_hls_directory_token_uses_hs256_prefix_and_path_based_url(): void
    {
        $guid = 'abc-123';
        $signed = $this->signer->signUrl(
            url: "https://vz-test.b-cdn.net/{$guid}/playlist.m3u8",
            securityKey: 'SecurityKey',
            expiresAt: 1_598_024_587,
            isDirectory: true,
            pathAllowed: "/{$guid}/",
        );

        $this->assertStringStartsWith('HS256-', $this->extractToken($signed));
        $this->assertStringContainsString('/bcdn_token=HS256-', $signed);
        $this->assertStringContainsString('token_path=%2F'.$guid.'%2F', $signed);
        $this->assertStringContainsString('&expires=1598024587', $signed);
        $this->assertStringEndsWith("/{$guid}/playlist.m3u8", $signed);
        $this->assertStringNotContainsString('?token=', $signed);
    }

    public function test_hls_directory_token_matches_official_reference_implementation(): void
    {
        require_once base_path('tests/fixtures/bunny_url_signing.php');

        $guid = 'abc-123';
        $url = "https://token-tester.b-cdn.net/{$guid}/playlist.m3u8";
        $expires = 1_598_024_587;

        $ours = $this->signer->signUrl(
            url: $url,
            securityKey: 'SecurityKey',
            expiresAt: $expires,
            isDirectory: true,
            pathAllowed: "/{$guid}/",
        );

        $official = sign_bcdn_url(
            $url,
            'SecurityKey',
            86400,
            '',
            true,
            "/{$guid}/",
            '',
            '',
            false,
            $expires,
            0,
        );

        $this->assertSame($this->extractToken($official), $this->extractToken($ours));
        $this->assertSame($official, $ours);
    }

    public function test_token_path_is_guid_directory_with_trailing_slash(): void
    {
        $guid = 'efa153ce-af4b-40d1-96da-13f7dfa7fc96';
        $signed = $this->signer->signUrl(
            url: "https://vz-example.b-cdn.net/{$guid}/playlist.m3u8",
            securityKey: 'SecurityKey',
            expiresAt: 1_700_000_000,
            isDirectory: true,
            pathAllowed: "/{$guid}/",
        );

        $this->assertStringContainsString('token_path=%2F'.$guid.'%2F', $signed);
    }

    public function test_directory_token_has_no_ip_binding_prefix_without_user_ip(): void
    {
        $signed = $this->signer->signUrl(
            url: 'https://vz-test.b-cdn.net/guid/playlist.m3u8',
            securityKey: 'SecurityKey',
            expiresAt: 1_700_000_000,
            isDirectory: true,
            pathAllowed: '/guid/',
            userIp: '',
        );

        $token = $this->extractToken($signed);

        $this->assertStringStartsWith('HS256-', $token);
        $this->assertStringNotContainsString('HS256-1-', $signed);
    }

    public function test_ip_binding_adds_flags_prefix_when_user_ip_is_set(): void
    {
        $signed = $this->signer->signUrl(
            url: 'https://token-tester.b-cdn.net/300kb.jpg',
            securityKey: 'SecurityKey',
            expiresAt: 1_598_024_587,
            userIp: '1.2.3.4',
        );

        $this->assertSame(
            'HS256-1-L2rISTLcujMY9UFf2tbZ41d5i-Bme1g1oTK_Z2QMLJk',
            $this->extractToken($signed),
        );
    }

    public function test_token_uses_base64url_without_padding(): void
    {
        $signed = $this->signer->signUrl(
            url: 'https://token-tester.b-cdn.net/300kb.jpg',
            securityKey: 'SecurityKey',
            expiresAt: 1_598_024_587,
        );

        $token = $this->extractToken($signed);
        $payload = substr($token, strlen('HS256-'));

        $this->assertDoesNotMatchRegularExpression('/[=+\\/]/', $payload);
        $this->assertMatchesRegularExpression('/^[A-Za-z0-9_-]+$/', $payload);
    }

    public function test_rejects_empty_security_key(): void
    {
        $this->expectException(InvalidArgumentException::class);

        $this->signer->signUrl(
            url: 'https://vz-test.b-cdn.net/guid/playlist.m3u8',
            securityKey: '',
            expiresAt: time() + 3600,
            isDirectory: true,
            pathAllowed: '/guid/',
        );
    }

    #[DataProvider('officialVectorProvider')]
    public function test_matches_all_official_reference_vectors(
        string $path,
        bool $isDirectory,
        string $pathAllowed,
        string $userIp,
        string $countriesAllowed,
        string $countriesBlocked,
        bool $ignoreParams,
        int $speedLimit,
        string $expectedToken,
    ): void {
        require_once base_path('tests/fixtures/bunny_url_signing.php');

        $url = 'https://token-tester.b-cdn.net'.$path;
        $expires = 1_598_024_587;

        $signed = $this->signer->signUrl(
            url: $url,
            securityKey: 'SecurityKey',
            expiresAt: $expires,
            isDirectory: $isDirectory,
            pathAllowed: $pathAllowed,
            userIp: $userIp,
            countriesAllowed: $countriesAllowed,
            countriesBlocked: $countriesBlocked,
            ignoreParams: $ignoreParams,
            speedLimit: $speedLimit,
        );

        $official = sign_bcdn_url(
            $url,
            'SecurityKey',
            86400,
            $userIp,
            $isDirectory,
            $pathAllowed,
            $countriesAllowed,
            $countriesBlocked,
            $ignoreParams,
            $expires,
            $speedLimit,
        );

        $this->assertSame($expectedToken, $this->extractToken($signed));
        $this->assertSame($official, $signed);
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public static function officialVectorProvider(): array
    {
        return [
            'plain' => ['/300kb.jpg', false, '', '', '', '', false, 0, 'HS256-o10JRWlsAItyAsdKS6jJKjabHN4FrFsplDHPV1idcX4'],
            'countries_only' => ['/300kb.jpg', false, '', '', 'CA,US', '', false, 0, 'HS256-i5s3Uv7mnrFfN5nznwU2BxhILpnipYeE18TapV0WNFM'],
            'blocked_only' => ['/300kb.jpg', false, '', '', '', 'RU,CN', false, 0, 'HS256-JS8dSuBSjSH-W2-xhdkCPC36-2rlxfDCQJjlNMPqKZQ'],
            'path_only' => ['/abc/300kb.jpg', false, '/abc', '', '', '', false, 0, 'HS256-uVZvT3SbEoVKYJyDJgbcsDmSFf73cv-uNUVaJiKWpbQ'],
            'ignore_params' => ['/300kb.jpg', false, '', '', '', '', true, 0, 'HS256-1lwWBD_c1IAGSj1UKPoxreu8ePDQ-Z9FoWLcRn_RRH0'],
            'limit_only' => ['/300kb.jpg', false, '', '', '', '', false, 1000, 'HS256-DAVapqNNED3Z7JkjRTYX0UOIHNtbHEuuhRNEc4A7mMQ'],
            'ip_v4_only' => ['/300kb.jpg', false, '', '1.2.3.4', '', '', false, 0, 'HS256-1-L2rISTLcujMY9UFf2tbZ41d5i-Bme1g1oTK_Z2QMLJk'],
            'ip_v6_only' => ['/300kb.jpg', false, '', '2001:0db8:85a3:0000:0000:8a2e:0370:7334', '', '', false, 0, 'HS256-1-Z1BaGdhTZdU4iANcyKpurFR2VgCNdqC6hlBv5x_TyaI'],
            'ip_v4_countries' => ['/abc/', true, '', '1.2.3.4', 'CA,US', '', false, 0, 'HS256-1-4lIDGI2_t3wiTmopXzB7z71wtZKTe1Ic0lDlL72iAJw'],
            'ip_v4_limit' => ['/abc/', true, '', '1.2.3.4', '', '', false, 5000, 'HS256-1-X01Z6A9xAo1_ds1XFf9y8gAIzk_JpmoevOx7EtgMQhY'],
            'ip_v4_path' => ['/abc/300kb.jpg', false, '/abc', '1.2.3.4', '', '', false, 0, 'HS256-1-wag9tC0r1QWfg-2eMj5QcdzgPLCIdQb-D0WVU1Mhg2w'],
            'ip_v4_ignore' => ['/300kb.jpg', false, '', '1.2.3.4', '', '', true, 0, 'HS256-1-rWalmQRJ-A_qrb08-JoeU3b-gOS5mJiJjPOfDWa0gsQ'],
            'ip_v4_blocked' => ['/300kb.jpg', false, '', '1.2.3.4', '', 'RU,CN', false, 0, 'HS256-1-myF6Rnz7Z9VAfAjjkyUHJQ_6gr-AJ7VyPsG5rQdQKm8'],
            'ip_v6_blocked' => ['/300kb.jpg', false, '', '2001:0db8:85a3:0000:0000:8a2e:0370:7334', '', 'RU,CN', false, 0, 'HS256-1-XGkCf_JKNfOrpWAM_CIYjZBbVHbB4U1mxHg8pXJtBNc'],
        ];
    }

    protected function extractToken(string $url): string
    {
        $marker = str_contains($url, 'bcdn_token=') ? 'bcdn_token=' : 'token=';
        $start = strpos($url, $marker) + strlen($marker);
        $end = strpos($url, '&', $start);

        if ($end === false) {
            $end = strlen($url);
        }

        return substr($url, $start, $end - $start);
    }
}
