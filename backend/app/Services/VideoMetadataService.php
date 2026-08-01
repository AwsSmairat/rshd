<?php

namespace App\Services;

class VideoMetadataService
{
    public function durationSeconds(string $absolutePath): ?int
    {
        if (! is_file($absolutePath)) {
            return null;
        }

        $ffprobe = $this->ffprobeBinary();
        if ($ffprobe === null) {
            return null;
        }

        $command = sprintf(
            '%s -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 %s 2>/dev/null',
            escapeshellarg($ffprobe),
            escapeshellarg($absolutePath),
        );

        $output = shell_exec($command);
        if (! is_string($output) || trim($output) === '') {
            return null;
        }

        $seconds = (float) trim($output);
        if ($seconds <= 0) {
            return null;
        }

        return (int) round($seconds);
    }

    public function isAvailable(): bool
    {
        return $this->ffprobeBinary() !== null;
    }

    protected function ffprobeBinary(): ?string
    {
        foreach (['ffprobe', '/opt/homebrew/bin/ffprobe', '/usr/local/bin/ffprobe'] as $candidate) {
            $path = trim((string) shell_exec(sprintf('command -v %s 2>/dev/null', escapeshellarg($candidate))));
            if ($path !== '' && is_executable($path)) {
                return $path;
            }
        }

        return null;
    }
}
