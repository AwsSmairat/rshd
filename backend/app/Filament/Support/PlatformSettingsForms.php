<?php

namespace App\Filament\Support;

use Filament\Forms;

class PlatformSettingsForms
{
    /**
     * @return list<Forms\Components\Component>
     */
    public static function upload(string $name, string $label, string $directory): Forms\Components\FileUpload
    {
        return Forms\Components\FileUpload::make($name)
            ->label($label)
            ->disk('public')
            ->directory($directory)
            ->visibility('public')
            ->image()
            ->imageEditor()
            ->maxSize(4096)
            ->acceptedFileTypes([
                'image/png',
                'image/jpeg',
                'image/webp',
                'image/svg+xml',
            ])
            ->downloadable()
            ->openable()
            ->columnSpanFull();
    }

    public static function toggle(string $name, string $label): Forms\Components\Toggle
    {
        return Forms\Components\Toggle::make($name)
            ->label($label)
            ->inline(false);
    }

    public static function url(string $name, string $label): Forms\Components\TextInput
    {
        return Forms\Components\TextInput::make($name)
            ->label($label)
            ->url()
            ->maxLength(255);
    }
}
