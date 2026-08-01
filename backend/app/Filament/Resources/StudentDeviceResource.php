<?php

namespace App\Filament\Resources;

use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Resources\StudentDeviceResource\Pages;
use App\Models\StudentDevice;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class StudentDeviceResource extends Resource
{
    use HasInstructorScope;

    protected static ?string $model = StudentDevice::class;

    protected static ?string $navigationIcon = 'heroicon-o-device-tablet';

    protected static ?string $navigationGroup = 'الإدارة';

    protected static ?string $navigationLabel = 'الأجهزة المرتبطة';

    protected static ?string $modelLabel = 'جهاز';

    protected static ?string $pluralModelLabel = 'الأجهزة المرتبطة';

    protected static ?int $navigationSort = 4;

    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function getEloquentQuery(): Builder
    {
        $query = parent::getEloquentQuery();

        if (static::isAdmin()) {
            return $query;
        }

        return $query->whereHas('student.enrolledSubjects', fn (Builder $q) => $q->where('instructor_id', static::authUser()?->id));
    }

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('student.name')
                    ->label('الطالب')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('device_id')
                    ->label('معرف الجهاز')
                    ->searchable(),
                Tables\Columns\TextColumn::make('device_name')
                    ->label('اسم الجهاز'),
                Tables\Columns\TextColumn::make('platform')
                    ->label('المنصة'),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('نشط')
                    ->boolean(),
                Tables\Columns\TextColumn::make('last_login_at')
                    ->label('آخر تسجيل دخول')
                    ->dateTime()
                    ->sortable(),
            ])
            ->actions([])
            ->bulkActions([]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListStudentDevices::route('/'),
        ];
    }
}
