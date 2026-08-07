<?php

namespace App\Filament\Resources;

use App\Enums\VideoStatus;
use App\Filament\Concerns\ChecksPlatformInstructorSettings;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Concerns\HasSubjectLessonFormFields;
use App\Filament\Resources\VideoResource\Pages;
use App\Models\Video;
use App\Services\VideoMetadataService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Storage;

class VideoResource extends Resource
{
    use ChecksPlatformInstructorSettings;
    use HasInstructorScope;
    use HasSubjectLessonFormFields;

    protected static ?string $model = Video::class;

    protected static ?string $navigationIcon = 'heroicon-o-film';

    protected static ?string $navigationGroup = 'التعليم';

    protected static ?string $navigationLabel = 'الفيديوهات';

    protected static ?string $modelLabel = 'فيديو';

    protected static ?string $pluralModelLabel = 'الفيديوهات';

    protected static ?int $navigationSort = 5;

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
                Forms\Components\Section::make('ملف الفيديو')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('العنوان')
                            ->required()
                            ->maxLength(255)
                            ->columnSpanFull(),
                        Forms\Components\FileUpload::make('video_path')
                            ->label('ملف الفيديو')
                            ->disk('lesson_videos')
                            ->directory('lesson-videos')
                            ->visibility('private')
                            ->acceptedFileTypes([
                                'video/mp4',
                                'video/webm',
                                'video/quicktime',
                                'video/x-msvideo',
                                'video/x-matroska',
                                'video/avi',
                                'application/octet-stream',
                            ])
                            ->maxSize(10485760)
                            ->storeFileNamesIn('original_file_name')
                            ->downloadable()
                            ->openable()
                            ->uploadingMessage('جاري رفع الفيديو...')
                            ->uploadProgressIndicatorPosition('left')
                            ->helperText('ارفع ملف الفيديو مباشرة (MP4, WebM, MOV, MKV). الحد الأقصى 10 جيجابايت. تأكد من تشغيل السيرفر عبر ./serve.sh')
                            ->required(fn (string $operation): bool => $operation === 'create')
                            ->columnSpanFull(),
                    ]),
                Forms\Components\Section::make('الإعدادات')
                    ->schema([
                        Forms\Components\Select::make('status')
                            ->label('الحالة')
                            ->options(VideoStatus::options())
                            ->default(VideoStatus::Ready->value)
                            ->required(),
                        Forms\Components\Toggle::make('is_free')
                            ->label('فيديو مجاني للمعاينة')
                            ->helperText('يمكن للطالب مشاهدته قبل تفعيل المادة (مثل اختبار / تيست).')
                            ->default(false),
                        Forms\Components\Hidden::make('storage_provider')
                            ->dehydrated(false),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('مزود التخزين')
                    ->schema([
                        Forms\Components\Placeholder::make('provider_label')
                            ->label('المزود')
                            ->content(fn (): string => config('video.provider', 'local') === 'bunny' ? 'Bunny Stream' : 'Local (Private)'),
                        Forms\Components\TextInput::make('external_video_id')
                            ->label('Bunny Video ID')
                            ->disabled()
                            ->dehydrated(false)
                            ->visible(fn (?Video $record): bool => $record?->storage_provider === 'bunny'),
                    ])
                    ->columns(2)
                    ->visible(fn (?Video $record): bool => $record !== null || config('video.provider') === 'bunny'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('lesson.title')
                    ->label('الجزء')
                    ->sortable()
                    ->searchable(),
                Tables\Columns\TextColumn::make('lesson.subject.title')
                    ->label('المادة')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable()
                    ->limit(30),
                Tables\Columns\TextColumn::make('original_file_name')
                    ->label('الملف')
                    ->formatStateUsing(fn (?string $state, Video $record): string => static::fileLabel($record))
                    ->limit(28),
                Tables\Columns\TextColumn::make('file_size')
                    ->label('الحجم')
                    ->formatStateUsing(fn (?int $state, Video $record): string => static::fileSizeLabel($state, $record))
                    ->toggleable(),
                Tables\Columns\TextColumn::make('duration_seconds')
                    ->label('المدة')
                    ->formatStateUsing(fn (?int $state): string => $state && $state > 0
                        ? gmdate($state >= 3600 ? 'H:i:s' : 'i:s', $state)
                        : '—')
                    ->sortable(),
                Tables\Columns\TextColumn::make('storage_provider')
                    ->label('المزود')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => $state === 'bunny' ? 'Bunny' : 'Local')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(function (VideoStatus|string|null $state): string {
                        if ($state instanceof VideoStatus) {
                            return $state->label();
                        }

                        return VideoStatus::tryFrom((string) $state)?->label() ?? (string) $state;
                    })
                    ->color(fn (VideoStatus|string|null $state): string => match ($state instanceof VideoStatus ? $state : VideoStatus::tryFrom((string) $state)) {
                        VideoStatus::Ready => 'success',
                        VideoStatus::Uploading, VideoStatus::Processing => 'warning',
                        VideoStatus::Failed => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\IconColumn::make('is_free')
                    ->label('مجاني')
                    ->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('subject_id')
                    ->label('المادة')
                    ->options(fn (): array => static::subjectFilterOptions())
                    ->searchable()
                    ->query(fn (Builder $query, array $data): Builder => static::applyLessonSubjectFilter($query, $data)),
                Tables\Filters\SelectFilter::make('status')
                    ->label('الحالة')
                    ->options(VideoStatus::options()),
                Tables\Filters\TernaryFilter::make('is_free')
                    ->label('مجاني للمعاينة'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد فيديوهات')
            ->emptyStateDescription('ارفع أول فيديو من زر «إضافة فيديو» واربطه بجزء من المادة.')
            ->emptyStateIcon('heroicon-o-film');
    }

    public static function fileLabel(Video $record): string
    {
        if ($record->original_file_name) {
            return $record->original_file_name;
        }

        if ($record->video_path) {
            return basename($record->video_path);
        }

        if ($record->video_url) {
            return 'رابط خارجي';
        }

        return '—';
    }

    public static function fileSizeLabel(?int $size, Video $record): string
    {
        if ($size && $size > 0) {
            return number_format($size / 1048576, 2).' MB';
        }

        if ($record->video_path) {
            return '—';
        }

        if ($record->video_url) {
            return 'خارجي';
        }

        return '—';
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    public static function prepareVideoData(array $data, ?Video $record = null): array
    {
        $newPath = $data['video_path'] ?? null;

        if (is_array($newPath)) {
            $newPath = $newPath[0] ?? null;
            $data['video_path'] = $newPath;
        }

        $usesBunny = config('video.provider', 'local') === 'bunny';

        if ($newPath && is_string($newPath)) {
            if ($record?->video_path && $record->video_path !== $newPath) {
                Storage::disk('lesson_videos')->delete($record->video_path);
                Storage::disk('public')->delete($record->video_path);
            }

            $disk = Storage::disk('lesson_videos');

            if ($disk->exists($newPath)) {
                $data['file_size'] = $disk->size($newPath);
                $data['file_mime_type'] = $disk->mimeType($newPath) ?: null;

                if (! $usesBunny) {
                    $duration = app(VideoMetadataService::class)
                        ->durationSeconds($disk->path($newPath));
                    if ($duration !== null) {
                        $data['duration_seconds'] = $duration;
                    }
                }
            }

            $data['video_url'] = '';

            if ($usesBunny) {
                $data['storage_provider'] = 'bunny';
                $data['status'] = VideoStatus::Uploading->value;
                $data['external_video_id'] = null;
            } else {
                $data['storage_provider'] = 'local';
                $data['status'] = VideoStatus::Ready->value;
            }
        } elseif ($record) {
            $data['video_path'] = $record->video_path;
            $data['video_url'] = $record->video_url;
            $data['file_size'] = $record->file_size;
            $data['file_mime_type'] = $record->file_mime_type;
            $data['duration_seconds'] = $record->duration_seconds;
            $data['original_file_name'] = $data['original_file_name'] ?? $record->original_file_name;
        }

        if (! filled($data['storage_provider'] ?? null)) {
            $data['storage_provider'] = config('video.provider') === 'bunny' ? 'bunny' : 'local';
        }

        $data['video_url'] = $data['video_url'] ?? '';

        return $data;
    }

    public static function canCreate(): bool
    {
        return static::instructorMay('instructor_can_upload_videos');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListVideos::route('/'),
            'create' => Pages\CreateVideo::route('/create'),
            'edit' => Pages\EditVideo::route('/{record}/edit'),
        ];
    }
}
