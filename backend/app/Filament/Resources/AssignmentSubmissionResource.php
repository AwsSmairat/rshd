<?php

namespace App\Filament\Resources;

use App\Filament\Concerns\ChecksPlatformInstructorSettings;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Resources\AssignmentSubmissionResource\Pages;
use App\Models\AssignmentSubmission;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\HtmlString;

class AssignmentSubmissionResource extends Resource
{
    use ChecksPlatformInstructorSettings;
    use HasInstructorScope;

    protected static ?string $model = AssignmentSubmission::class;

    protected static ?string $navigationIcon = 'heroicon-o-inbox-arrow-down';

    protected static ?string $navigationGroup = 'التعليم';

    protected static ?string $navigationLabel = 'تسليمات الواجبات';

    protected static ?string $modelLabel = 'تسليم';

    protected static ?string $pluralModelLabel = 'تسليمات الواجبات';

    protected static ?int $navigationSort = 4;

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit(Model $record): bool
    {
        return static::instructorMay('instructor_can_grade_assignments');
    }

    public static function getEloquentQuery(): Builder
    {
        return static::scopeBySubjectInstructor(
            parent::getEloquentQuery(),
            'assignment.subject',
        );
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('معلومات التسليم')
                    ->schema([
                        Forms\Components\TextInput::make('assignment.title')
                            ->label('الواجب')
                            ->disabled(),
                        Forms\Components\TextInput::make('student.name')
                            ->label('الطالب')
                            ->disabled(),
                        Forms\Components\DateTimePicker::make('submitted_at')
                            ->label('تاريخ التسليم')
                            ->disabled(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('إجابة الطالب')
                    ->schema([
                        Forms\Components\Textarea::make('answer_text')
                            ->label('نص الإجابة')
                            ->columnSpanFull()
                            ->disabled()
                            ->placeholder('—'),
                        Forms\Components\Placeholder::make('file_link')
                            ->label('ملف الحل')
                            ->content(function (?AssignmentSubmission $record): HtmlString|string {
                                if ($record === null) {
                                    return '—';
                                }

                                $url = $record->resolvedFileUrl();
                                if ($url === null) {
                                    return 'لا يوجد ملف مرفق';
                                }

                                $name = $record->original_file_name ?? 'فتح الملف';

                                return new HtmlString(
                                    '<a href="'.e($url).'" target="_blank" rel="noopener" class="text-primary-600 underline font-medium">'
                                    .e($name)
                                    .'</a>'
                                );
                            })
                            ->visible(fn (?AssignmentSubmission $record): bool => $record?->resolvedFileUrl() !== null)
                            ->columnSpanFull(),
                    ]),
                Forms\Components\Section::make('التقييم')
                    ->schema([
                        Forms\Components\TextInput::make('grade')
                            ->label('الدرجة')
                            ->numeric()
                            ->minValue(0)
                            ->maxValue(100)
                            ->suffix('/ 100'),
                        Forms\Components\Textarea::make('feedback')
                            ->label('ملاحظات المدرس')
                            ->rows(4)
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
            ]);
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                Infolists\Components\Section::make('معلومات التسليم')
                    ->schema([
                        Infolists\Components\TextEntry::make('assignment.title')
                            ->label('الواجب'),
                        Infolists\Components\TextEntry::make('assignment.subject.title')
                            ->label('المادة'),
                        Infolists\Components\TextEntry::make('student.name')
                            ->label('الطالب'),
                        Infolists\Components\TextEntry::make('submitted_at')
                            ->label('تاريخ التسليم')
                            ->dateTime('Y-m-d H:i')
                            ->placeholder('—'),
                    ])
                    ->columns(2),
                Infolists\Components\Section::make('إجابة الطالب')
                    ->schema([
                        Infolists\Components\TextEntry::make('answer_text')
                            ->label('نص الإجابة')
                            ->placeholder('—')
                            ->columnSpanFull(),
                        Infolists\Components\TextEntry::make('original_file_name')
                            ->label('ملف الحل')
                            ->url(fn (AssignmentSubmission $record): ?string => $record->resolvedFileUrl())
                            ->openUrlInNewTab()
                            ->placeholder('لا يوجد ملف'),
                    ]),
                Infolists\Components\Section::make('التقييم')
                    ->schema([
                        Infolists\Components\TextEntry::make('grade')
                            ->label('الدرجة')
                            ->formatStateUsing(fn (?string $state): string => $state !== null ? $state.' / 100' : 'بانتظار التقييم')
                            ->color(fn (?string $state): string => $state !== null ? 'success' : 'warning'),
                        Infolists\Components\TextEntry::make('feedback')
                            ->label('ملاحظات المدرس')
                            ->placeholder('—')
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('submitted_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('assignment.title')
                    ->label('الواجب')
                    ->sortable()
                    ->searchable()
                    ->limit(30),
                Tables\Columns\TextColumn::make('assignment.subject.title')
                    ->label('المادة')
                    ->sortable()
                    ->searchable()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('student.name')
                    ->label('الطالب')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\IconColumn::make('file_path')
                    ->label('ملف')
                    ->boolean()
                    ->getStateUsing(fn (AssignmentSubmission $record): bool => $record->resolvedFileUrl() !== null)
                    ->trueIcon('heroicon-o-paper-clip')
                    ->falseIcon('heroicon-o-minus')
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('grade')
                    ->label('الدرجة')
                    ->formatStateUsing(fn (?string $state): string => $state !== null ? $state.' / 100' : 'بانتظار التقييم')
                    ->badge()
                    ->color(fn (?string $state): string => $state !== null ? 'success' : 'warning'),
                Tables\Columns\TextColumn::make('submitted_at')
                    ->label('تاريخ التسليم')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->placeholder('—'),
            ])
            ->filters([
                Tables\Filters\Filter::make('ungraded')
                    ->label('بانتظار التقييم')
                    ->query(fn (Builder $query): Builder => $query->whereNull('grade')),
                Tables\Filters\Filter::make('graded')
                    ->label('مقيّمة')
                    ->query(fn (Builder $query): Builder => $query->whereNotNull('grade')),
                Tables\Filters\Filter::make('with_file')
                    ->label('مع ملف')
                    ->query(fn (Builder $query): Builder => $query->where(function (Builder $inner): void {
                        $inner->whereNotNull('file_path')
                            ->orWhereNotNull('file_url');
                    })),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make()
                    ->label('تقييم'),
            ])
            ->bulkActions([])
            ->emptyStateHeading('لا توجد تسليمات')
            ->emptyStateDescription('عندما يسلّم الطلاب واجباتهم من التطبيق، ستظهر هنا للمراجعة والتقييم.')
            ->emptyStateIcon('heroicon-o-inbox-arrow-down');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAssignmentSubmissions::route('/'),
            'view' => Pages\ViewAssignmentSubmission::route('/{record}'),
            'edit' => Pages\EditAssignmentSubmission::route('/{record}/edit'),
        ];
    }
}
