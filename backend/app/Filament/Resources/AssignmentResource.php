<?php

namespace App\Filament\Resources;

use App\Enums\ContentStatus;
use App\Filament\Concerns\ChecksPlatformInstructorSettings;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Concerns\HasSubjectLessonFormFields;
use App\Filament\Resources\AssignmentResource\Pages;
use App\Models\Assignment;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Storage;

class AssignmentResource extends Resource
{
    use ChecksPlatformInstructorSettings;
    use HasInstructorScope;
    use HasSubjectLessonFormFields;

    protected static ?string $model = Assignment::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-text';

    protected static ?string $navigationGroup = 'التعليم';

    protected static ?string $navigationLabel = 'الواجبات';

    protected static ?string $modelLabel = 'واجب';

    protected static ?string $pluralModelLabel = 'الواجبات';

    protected static ?int $navigationSort = 2;

    public static function getEloquentQuery(): Builder
    {
        return static::scopeBySubjectInstructor(parent::getEloquentQuery());
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('المادة والجزء')
                    ->schema([
                        ...static::subjectThenLessonFields(
                            subjectPersistsOnModel: true,
                            lessonRequired: false,
                            lessonLabel: 'الجزء',
                        ),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('تفاصيل الواجب')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('العنوان')
                            ->required()
                            ->maxLength(255)
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('description')
                            ->label('الوصف')
                            ->rows(4)
                            ->columnSpanFull(),
                        Forms\Components\FileUpload::make('attachment_path')
                            ->label('ملف الواجب')
                            ->disk('public')
                            ->directory('assignments/attachments')
                            ->visibility('public')
                            ->acceptedFileTypes([
                                'application/pdf',
                                'application/msword',
                                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                'application/vnd.ms-powerpoint',
                                'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                'application/vnd.ms-excel',
                                'image/jpeg',
                                'image/png',
                                'image/webp',
                                'text/plain',
                                'application/zip',
                            ])
                            ->maxSize(51200)
                            ->storeFileNamesIn('original_file_name')
                            ->downloadable()
                            ->openable()
                            ->helperText('ارفع ملف الواجب (PDF، Word، PowerPoint، Excel، صورة، ZIP). الحد الأقصى 50 ميجابايت.')
                            ->columnSpanFull(),
                        Forms\Components\DateTimePicker::make('due_date')
                            ->label('تاريخ التسليم')
                            ->helperText('اختياري — يُستخدم لتذكير الطلاب بموعد التسليم.'),
                        Forms\Components\Select::make('status')
                            ->label('الحالة')
                            ->options(ContentStatus::options())
                            ->default(ContentStatus::Active->value)
                            ->required(),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->withCount('submissions'))
            ->defaultSort('due_date', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('subject.title')
                    ->label('المادة')
                    ->sortable()
                    ->searchable()
                    ->limit(28),
                Tables\Columns\TextColumn::make('lesson.title')
                    ->label('الجزء')
                    ->placeholder('—')
                    ->limit(24)
                    ->toggleable(),
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable()
                    ->limit(35),
                Tables\Columns\IconColumn::make('attachment_path')
                    ->label('ملف')
                    ->boolean()
                    ->trueIcon('heroicon-o-paper-clip')
                    ->falseIcon('heroicon-o-minus')
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('original_file_name')
                    ->label('اسم الملف')
                    ->placeholder('—')
                    ->limit(28)
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('due_date')
                    ->label('تاريخ التسليم')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->placeholder('—')
                    ->color(fn (Assignment $record): string => $record->due_date
                        && $record->due_date->isPast()
                        && $record->status === ContentStatus::Active
                        ? 'danger'
                        : 'gray'),
                Tables\Columns\TextColumn::make('submissions_count')
                    ->label('التسليمات')
                    ->sortable()
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(function (ContentStatus|string|null $state): string {
                        if ($state instanceof ContentStatus) {
                            return $state->label();
                        }

                        return ContentStatus::tryFrom((string) $state)?->label() ?? (string) $state;
                    })
                    ->color(fn (ContentStatus|string|null $state): string => match ($state instanceof ContentStatus ? $state : ContentStatus::tryFrom((string) $state)) {
                        ContentStatus::Active => 'success',
                        ContentStatus::Inactive => 'gray',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
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
                Tables\Filters\SelectFilter::make('status')
                    ->label('الحالة')
                    ->options(ContentStatus::options()),
                Tables\Filters\Filter::make('overdue')
                    ->label('متأخرة')
                    ->query(fn (Builder $query): Builder => $query
                        ->where('status', ContentStatus::Active)
                        ->whereNotNull('due_date')
                        ->where('due_date', '<', now())),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد واجبات')
            ->emptyStateDescription('ابدأ بإنشاء أول واجب من زر «إضافة واجب».')
            ->emptyStateIcon('heroicon-o-document-text');
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    public static function prepareAttachmentData(array $data, ?Assignment $record = null): array
    {
        $newPath = $data['attachment_path'] ?? null;

        if (is_array($newPath)) {
            $newPath = $newPath[0] ?? null;
            $data['attachment_path'] = $newPath;
        }

        if ($newPath && is_string($newPath)) {
            if ($record?->attachment_path && $record->attachment_path !== $newPath) {
                Storage::disk('public')->delete($record->attachment_path);
            }

            $disk = Storage::disk('public');

            if ($disk->exists($newPath)) {
                $data['file_size'] = $disk->size($newPath);
                $data['file_mime_type'] = $disk->mimeType($newPath) ?: null;
            }
        } elseif ($record) {
            if (array_key_exists('attachment_path', $data) && blank($data['attachment_path'])) {
                if ($record->attachment_path) {
                    Storage::disk('public')->delete($record->attachment_path);
                }

                $data['attachment_path'] = null;
                $data['file_size'] = null;
                $data['file_mime_type'] = null;
                $data['original_file_name'] = null;
            } else {
                $data['attachment_path'] = $record->attachment_path;
                $data['file_size'] = $record->file_size;
                $data['file_mime_type'] = $record->file_mime_type;
                $data['original_file_name'] = $data['original_file_name'] ?? $record->original_file_name;
            }
        } else {
            $data['attachment_path'] = null;
            $data['file_size'] = null;
            $data['file_mime_type'] = null;
            $data['original_file_name'] = null;
        }

        return $data;
    }

    public static function canCreate(): bool
    {
        return static::instructorMay('instructor_can_create_assignments');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAssignments::route('/'),
            'create' => Pages\CreateAssignment::route('/create'),
            'edit' => Pages\EditAssignment::route('/{record}/edit'),
        ];
    }
}
