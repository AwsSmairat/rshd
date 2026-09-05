<?php

namespace Tests\Unit;

use App\Services\LessonFiles\OfficeToPdfConverter;
use Illuminate\Filesystem\Filesystem;
use PHPUnit\Framework\TestCase;

class OfficeToPdfConverterTest extends TestCase
{
    public function test_libreoffice_conversion_uses_isolated_writable_profile_and_cleans_it_up(): void
    {
        $root = sys_get_temp_dir().'/rshd-office-test-'.bin2hex(random_bytes(6));
        $filesystem = new Filesystem();

        mkdir($root, 0775, true);

        $binary = $root.'/soffice';
        $source = $root.'/input.docx';
        $destination = $root.'/output.pdf';

        file_put_contents($source, 'fake-docx');

        file_put_contents($binary, <<<'SH'
#!/bin/sh
set -eu

outdir=""
profile=""
source=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -env:UserInstallation=*)
            profile="${1#-env:UserInstallation=}"
            shift
            ;;
        --outdir)
            outdir="$2"
            shift 2
            ;;
        --convert-to)
            shift 2
            ;;
        --headless|--norestore)
            shift
            ;;
        *)
            source="$1"
            shift
            ;;
    esac
done

[ -n "$outdir" ]
[ -n "$profile" ]
[ -n "$source" ]

[ "$HOME" = "$outdir" ]
[ "$XDG_CONFIG_HOME" = "$outdir/.config" ]
[ "$XDG_CACHE_HOME" = "$outdir/.cache" ]

[ -d "$HOME" ]
[ -w "$HOME" ]
[ -d "$XDG_CONFIG_HOME" ]
[ -w "$XDG_CONFIG_HOME" ]
[ -d "$XDG_CACHE_HOME" ]
[ -w "$XDG_CACHE_HOME" ]

case "$profile" in
    "file://$outdir/profile") ;;
    *) exit 41 ;;
esac

profile_path="${profile#file://}"
mkdir -p "$profile_path/nested"
printf 'profile-marker\n' > "$profile_path/nested/marker"

name="$(basename "$source")"
name="${name%.*}"

printf '%%PDF-1.4 fake-office-preview\n' > "$outdir/$name.pdf"
SH);

        chmod($binary, 0755);

        $converter = new class($binary) extends OfficeToPdfConverter
        {
            public function __construct(
                private readonly string $binary,
            ) {}

            protected function libreOfficeBinary(): ?string
            {
                return $this->binary;
            }
        };

        try {
            $converter->convert($source, $destination, 'docx');

            $this->assertFileExists($destination);
            $this->assertGreaterThan(0, filesize($destination));
            $this->assertStringStartsWith('%PDF-', (string) file_get_contents($destination));
            $this->assertSame([], glob($root.'/lo-*') ?: []);
        } finally {
            $filesystem->deleteDirectory($root);
        }
    }
}
