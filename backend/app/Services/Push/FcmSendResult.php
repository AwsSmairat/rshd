<?php

namespace App\Services\Push;

/**
 * What FCM said about one send.
 */
final class FcmSendResult
{
    private function __construct(
        public readonly int $status,
        public readonly ?string $errorCode,
        public readonly string $errorMessage = '',
    ) {}

    /**
     * @param  array<string, mixed>  $body
     */
    public static function fromResponse(int $status, array $body): self
    {
        $errorCode = null;

        foreach ((array) data_get($body, 'error.details', []) as $detail) {
            if (is_array($detail) && isset($detail['errorCode'])) {
                $errorCode = (string) $detail['errorCode'];
                break;
            }
        }

        if ($errorCode === null && $status >= 400) {
            $errorCode = (string) data_get($body, 'error.status', 'UNKNOWN');
        }

        return new self($status, $errorCode, (string) data_get($body, 'error.message', ''));
    }

    public function successful(): bool
    {
        return $this->status >= 200 && $this->status < 300;
    }

    /**
     * The token no longer belongs to an install (app removed, token rotated)
     * or was never valid; it should be forgotten.
     */
    public function tokenIsDead(): bool
    {
        if ($this->status === 404 || in_array($this->errorCode, ['UNREGISTERED', 'SENDER_ID_MISMATCH'], true)) {
            return true;
        }

        // INVALID_ARGUMENT also covers a malformed message; only a rejected
        // token should cost the device its registration.
        return $this->status === 400
            && $this->errorCode === 'INVALID_ARGUMENT'
            && str_contains(strtolower($this->errorMessage), 'registration token');
    }

    /**
     * A temporary failure worth retrying later.
     */
    public function isTransient(): bool
    {
        return $this->status === 429
            || $this->status >= 500
            || in_array($this->errorCode, ['UNAVAILABLE', 'INTERNAL', 'QUOTA_EXCEEDED'], true);
    }
}
