<?php

namespace App\Filament\Resources;

use App\Enums\FileType;
use App\Filament\Concerns\ChecksPlatformInstructorSettings;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Concerns\HasSubjectLessonFormFields;
use App\Filament\Resources\LessonFileResource\Pages;
use App\Models\LessonFile;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Get;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Storage;

class LessonFileResource extends Resource
{
    use ChecksPlatformInstructorSettings;
    use HasInstructorScope;
    use HasSubjectLessonFormFields;

    protected static ?string $model = LessonFile::class;

    protected static ?string $navigationIcon = 'heroicon-o-document';

    protected static ?string $navigationGroup = 'التعليم';

    protected static ?string $navigationLabel = 'ملفات الدروس';

    protected static ?string $modelLabel = 'ملف';

    protected static ?string $pluralModelLabel = 'ملفات الدروس';

    protected static ?int $navigationSort = 6;

    public static function getEloquentQuery(): Builder
    {
        return static::scopeBySubjectInstructor(
            parent::getEloquentQuery(),
            'lesson.subject',
        );
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('المادة والجزء')
                    ->schema([
                        ...static::subjectThenLessonFields(
                            subjectPersistsOnModel: false,
                            lessonRequired: true,
                            lessonLabel: 'الجزء',
                        ),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('الملف')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('العنوان')
                            ->required()
                            ->maxLength(255)
                            ->columnSpanFull(),
                        Forms\Components\Select::make('file_type')
                            ->label('نوع الملف')
                            ->options(FileType::options())
                            ->required(),
                        Forms\Components\FileUpload::make('file_path')
                            ->label('رفع ملف')
                            ->disk('public')
                            ->directory('lesson-files')
                            ->visibility('public')
                            ->acceptedFileTypes([
                                'application/pdf',
                                'application/msword',
                                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                'application/vnd.ms-powerpoint',
                                'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
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
                            ->live()
                            ->helperText('PDF، Word، PowerPoint، Excel، صور، ZIP — حتى 50 ميجابايت.')
                            ->columnSpanFull(),
                        Forms\Components\TextInput::make('file_url')
                            ->label('أو رابط خارجي')
                            ->url()
                            ->maxLength(2048)
                            ->visible(fn (Get $get): bool => blank($get('file_path')))
                            ->required(fn (Get $get, string $operation): bool => blank($get('file_path')) && $operation === 'create')
                            ->helperText('استخدمه فقط إذا الملف مستضاف خارج المنصة.'),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('lesson.subject.title')
                    ->label('المادة')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('lesson.title')
                    ->label('الجزء')
                    ->sortable()
                    ->searchable(),
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->limit(30),
                Tables\Columns\TextColumn::make('original_file_name')
                    ->label('الملف')
                    ->formatStateUsing(fn (?string $state, LessonFile $record): string => $state
                        ?? ($record->file_path ? basename($record->file_path) : 'رابط خارجي'))
                    ->limit(28),
                Tables\Columns\TextColumn::make('file_type')
                    ->label('النوع')
                    ->badge()
                    ->formatStateUsing(fn (FileType|string|null $state): string => match ($state instanceof FileType ? $state : FileType::tryFrom((string) $state)) {
                        FileType::Pdf => FileType::Pdf->label(),
                        FileType::Ppt => FileType::Ppt->label(),
                        FileType::Doc => FileType::Doc->label(),
                        FileType::Image => FileType::Image->label(),
                        FileType::Other => FileType::Other->label(),
                        default => (string) $state,
                    }),
                Tables\Columns\TextColumn::make('file_size')
                    ->label('الحجم')
                    ->formatStateUsing(fn (?int $state): string => $state && $state > 0
                        ? number_format($state / 1048576, 2).' MB'
                        : '—'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('subject_id')
                    ->label('المادة')
                    ->options(fn (): array => static::subjectFilterOptions())
                    ->searchable()
                    ->query(fn (Builder $query, array $data): Builder => static::applyLessonSubjectFilter($query, $data)),
                Tables\Filters\SelectFilter::make('file_type')
                    ->label('النوع')
                    ->options(FileType::options()),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد ملفات')
            ->emptyStateDescription('ارفع ملفات المحاضرة (PDF، Word...) واربطها بجزء من المادة.')
            ->emptyStateIcon('heroicon-o-document');
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    public static function prepareFileData(array $data, ?LessonFile $record = null): array
    {
        $newPath = $data['file_path'] ?? null;

        if (is_array($newPath)) {
            $newPath = $newPath[0] ?? null;
            $data['file_path'] = $newPath;
        }

        if ($newPath && is_string($newPath)) {
            if ($record?->file_path && $record->file_path !== $newPath) {
                Storage::disk('public')->delete($record->file_path);
            }

            $disk = Storage::disk('public');

            if ($disk->exists($newPath)) {
                $data['file_size'] = $disk->size($newPath);
                $data['file_mime_type'] = $disk->mimeType($newPath) ?: null;
            }

            $data['file_url'] = $disk->url($newPath);
        } elseif ($record) {
            if (array_key_exists('file_path', $data) && blank($data['file_path'])) {
                if ($record->file_path) {
                    Storage::disk('public')->delete($record->file_path);
                }

                $data['file_path'] = null;
                $data['file_mime_type'] = null;
                $data['file_size'] = $record->file_size;
                $data['original_file_name'] = null;
                $data['file_url'] = $data['file_url'] ?? $record->file_url;
            } else {
                $data['file_path'] = $record->file_path;
                $data['file_url'] = $data['file_url'] ?? $record->file_url;
                $data['file_size'] = $record->file_size;
                $data['file_mime_type'] = $record->file_mime_type;
                $data['original_file_name'] = $data['original_file_name'] ?? $record->original_file_name;
            }
        }

        if (blank($data['file_url'] ?? null) && blank($data['file_path'] ?? null)) {
            throw \Illuminate\Validation\ValidationException::withMessages([
                'file_path' => 'ارفع ملفاً أو أدخل رابطاً خارجياً.',
            ]);
        }

        return $data;
    }

    public static function canCreate(): bool
    {
        return static::instructorMay('instructor_can_upload_files');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListLessonFiles::route('/'),
            'create' => Pages\CreateLessonFile::route('/create'),
            'edit' => Pages\EditLessonFile::route('/{record}/edit'),
        ];
    }
}
