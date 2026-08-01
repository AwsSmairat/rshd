<?php

namespace App\Filament\Resources;

use App\Enums\GradeSourceType;
use App\Enums\UserRole;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Resources\GradeResource\Pages;
use App\Models\Grade;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Get;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class GradeResource extends Resource
{
    use HasInstructorScope;

    protected static ?string $model = Grade::class;

    protected static ?string $navigationIcon = 'heroicon-o-star';

    protected static ?string $navigationGroup = 'التعليم';

    protected static ?string $navigationLabel = 'الدرجات';

    protected static ?string $modelLabel = 'درجة';

    protected static ?string $pluralModelLabel = 'الدرجات';

    protected static ?int $navigationSort = 9;

    public static function getEloquentQuery(): Builder
    {
        return static::scopeBySubjectInstructor(parent::getEloquentQuery());
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('الطالب والمادة')
                    ->schema([
                        Forms\Components\Select::make('student_id')
                            ->label('الطالب')
                            ->relationship(
                                'student',
                                'name',
                                fn (Builder $query) => $query->where('role', UserRole::Student),
                            )
                            ->searchable()
                            ->preload()
                            ->required(),
                        Forms\Components\Select::make('subject_id')
                            ->label('المادة')
                            ->relationship(
                                'subject',
                                'title',
                                fn (Builder $query) => static::scopeSubjectsQuery($query),
                            )
                            ->searchable()
                            ->preload()
                            ->required(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('تفاصيل الدرجة')
                    ->schema([
                        Forms\Components\Select::make('source_type')
                            ->label('المصدر')
                            ->options(GradeSourceType::options())
                            ->default(GradeSourceType::Manual->value)
                            ->required()
                            ->live(),
                        Forms\Components\TextInput::make('source_id')
                            ->label('معرف المصدر')
                            ->numeric()
                            ->helperText('يُستخدم عند الربط باختبار أو واجب محدد.')
                            ->visible(fn (Get $get): bool => in_array($get('source_type'), [
                                GradeSourceType::Assignment->value,
                                GradeSourceType::Quiz->value,
                            ], true)),
                        Forms\Components\TextInput::make('grade')
                            ->label('الدرجة')
                            ->numeric()
                            ->minValue(0)
                            ->maxValue(100)
                            ->suffix('/ 100')
                            ->required(),
                        Forms\Components\Textarea::make('notes')
                            ->label('ملاحظات')
                            ->rows(3)
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('student.name')
                    ->label('الطالب')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('subject.title')
                    ->label('المادة')
                    ->sortable()
                    ->searchable(),
                Tables\Columns\TextColumn::make('source_type')
                    ->label('المصدر')
                    ->badge()
                    ->formatStateUsing(function (GradeSourceType|string|null $state): string {
                        if ($state instanceof GradeSourceType) {
                            return $state->label();
                        }

                        return GradeSourceType::tryFrom((string) $state)?->label() ?? (string) $state;
                    })
                    ->color(fn (GradeSourceType|string|null $state): string => match ($state instanceof GradeSourceType ? $state : GradeSourceType::tryFrom((string) $state)) {
                        GradeSourceType::Assignment => 'info',
                        GradeSourceType::Quiz => 'warning',
                        GradeSourceType::Manual => 'gray',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('grade')
                    ->label('الدرجة')
                    ->formatStateUsing(fn (?string $state): string => $state !== null ? $state.' / 100' : '—')
                    ->sortable()
                    ->badge()
                    ->color('success'),
                Tables\Columns\TextColumn::make('notes')
                    ->label('ملاحظات')
                    ->limit(30)
                    ->placeholder('—')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإضافة')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('subject_id')
                    ->label('المادة')
                    ->relationship(
                        'subject',
                        'title',
                        fn (Builder $query) => static::scopeSubjectsQuery($query),
                    )
                    ->searchable()
                    ->preload(),
                Tables\Filters\SelectFilter::make('source_type')
                    ->label('المصدر')
                    ->options(GradeSourceType::options()),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد درجات')
            ->emptyStateDescription('تُسجَّل الدرجات تلقائياً عند تقييم الواجبات، أو أضف درجة يدوياً من زر «إضافة درجة».')
            ->emptyStateIcon('heroicon-o-star');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListGrades::route('/'),
            'create' => Pages\CreateGrade::route('/create'),
            'edit' => Pages\EditGrade::route('/{record}/edit'),
        ];
    }
}
