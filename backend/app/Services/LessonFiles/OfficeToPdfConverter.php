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

        if (! @mkdir($outputDir, 0775, true) && ! is_dir($outputDir)) {
            return false;
        }

        try {
            $process = new Process([
                $binary,
                '--headless',
                '--norestore',
                '--convert-to',
                'pdf',
                '--outdir',
                $outputDir,
                $sourcePath,
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

        foreach (glob($directory.'/*') ?: [] as $entry) {
            if (is_file($entry)) {
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
            'soffice',
            'libreoffice',
            '/usr/bin/soffice',
            '/usr/bin/libreoffice',
            '/Applications/LibreOffice.app/Contents/MacOS/soffice',
        ];

        foreach ($candidates as $candidate) {
            if ($candidate === 'soffice' || $candidate === 'libreoffice') {
                $process = Process::fromShellCommandline('command -v '.escapeshellarg($candidate));
                $process->run();

                if ($process->isSuccessful() && is_executable(trim($process->getOutput()))) {
                    return trim($process->getOutput());
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
