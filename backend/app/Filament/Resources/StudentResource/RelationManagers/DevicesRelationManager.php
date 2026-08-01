<?php

namespace App\Filament\Resources\StudentResource\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class DevicesRelationManager extends RelationManager
{
    protected static string $relationship = 'studentDevices';

    protected static ?string $title = 'الأجهزة';

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('device_id')
                    ->label('معرف الجهاز'),
                Tables\Columns\TextColumn::make('device_name')
                    ->label('اسم الجهاز'),
                Tables\Columns\TextColumn::make('platform')
                    ->label('المنصة'),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('نشط')
                    ->boolean(),
                Tables\Columns\TextColumn::make('last_login_at')
                    ->label('آخر تسجيل دخول')
                    ->dateTime(),
            ])
            ->headerActions([])
            ->actions([])
            ->bulkActions([]);
    }
}
