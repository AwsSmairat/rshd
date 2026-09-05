<?php

namespace App\Services\LessonFiles;

use PhpOffice\PhpWord\IOFactory;
use PhpOffice\PhpWord\Settings;
use RuntimeException;
use Symfony\Component\Process\Process;

class OfficeToPdfConverter
{
    public function convert(string $sourcePath, string $destinationPath, string $extension): void
    {
        $extension = strtolower(ltrim($extension, '.'));

        if ($this->convertWithLibreOffice($sourcePath, $destinationPath)) {
            return;
        }

        if (in_array($extension, ['doc', 'docx'], true) && $this->convertWithPhpWord($sourcePath, $destinationPath)) {
            return;
        }

        throw new RuntimeException('تعذر تحويل الملف للعرض داخل التطبيق.');
    }

    protected function convertWithLibreOffice(string $sourcePath, string $destinationPath): bool
    {
        $binary = $this->libreOfficeBinary();

        if ($binary === null) {
            return false;
        }

        // LibreOffice names its output after the source file, so two conversions
        // of same-named sources would overwrite each other in a shared folder.
        $outputDir = dirname($destinationPath).'/lo-'.bin2hex(random_bytes(8));
        $profileDir = $outputDir.'/profile';
        $configDir = $outputDir.'/.config';
        $cacheDir = $outputDir.'/.cache';

        if (! @mkdir($outputDir, 0775, true) && ! is_dir($outputDir)) {
            return false;
        }

        @mkdir($configDir, 0775, true);
        @mkdir($cacheDir, 0775, true);

        try {
            $process = new Process([
                $binary,
                '-env:UserInstallation=file://'.$profileDir,
                '--headless',
                '--norestore',
                '--convert-to',
                'pdf',
                '--outdir',
                $outputDir,
                $sourcePath,
            ], sys_get_temp_dir(), [
                'HOME' => $outputDir,
                'XDG_CONFIG_HOME' => $configDir,
                'XDG_CACHE_HOME' => $cacheDir,
            ]);
            $process->setTimeout(90);
            $process->run();

            if (! $process->isSuccessful()) {
                return false;
            }

            $generated = $outputDir.'/'.pathinfo($sourcePath, PATHINFO_FILENAME).'.pdf';

            if (! is_file($generated) || filesize($generated) === 0) {
                return false;
            }

            return rename($generated, $destinationPath);
        } finally {
            $this->removeDirectory($outputDir);
        }
    }

    protected function removeDirectory(string $directory): void
    {
        if (! is_dir($directory)) {
            return;
        }

        foreach (array_diff(scandir($directory) ?: [], ['.', '..']) as $name) {
            $entry = $directory.'/'.$name;

            if (is_dir($entry) && ! is_link($entry)) {
                $this->removeDirectory($entry);
            } else {
                @unlink($entry);
            }
        }

        @rmdir($directory);
    }

    protected function convertWithPhpWord(string $sourcePath, string $destinationPath): bool
    {
        if (! class_exists(IOFactory::class)) {
            return false;
        }

        try {
            $rendererPath = base_path('vendor/dompdf/dompdf');

            if (! is_dir($rendererPath)) {
                return false;
            }

            Settings::setPdfRendererName(
                Settings::PDF_RENDERER_DOMPDF,
            );
            Settings::setPdfRendererPath($rendererPath);

            $phpWord = IOFactory::load($sourcePath);
            $writer = IOFactory::createWriter($phpWord, 'PDF');
            $writer->save($destinationPath);
        } catch (\Throwable) {
            return false;
        }

        return is_file($destinationPath) && filesize($destinationPath) > 0;
    }

    protected function libreOfficeBinary(): ?string
    {
        $candidates = [
            '/usr/bin/soffice',
            '/usr/bin/libreoffice',
            '/Applications/LibreOffice.app/Contents/MacOS/soffice',
            'soffice',
            'libreoffice',
        ];

        foreach ($candidates as $candidate) {
            if ($candidate === 'soffice' || $candidate === 'libreoffice') {
                try {
                    $process = Process::fromShellCommandline(
                        'command -v '.escapeshellarg($candidate),
                        sys_get_temp_dir(),
                    );
                    $process->run();

                    if ($process->isSuccessful() && is_executable(trim($process->getOutput()))) {
                        return trim($process->getOutput());
                    }
                } catch (\Throwable) {
                    continue;
                }

                continue;
            }

            if (is_executable($candidate)) {
                return $candidate;
            }
        }

        return null;
    }
}
