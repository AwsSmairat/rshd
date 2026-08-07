<?php

namespace App\Filament\Resources;

use App\Enums\LegalDocumentStatus;
use App\Enums\LegalDocumentType;
use App\Filament\Resources\LegalDocumentResource\Pages;
use App\Models\LegalDocument;
use App\Services\LegalDocumentService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class LegalDocumentResource extends Resource
{
    protected static ?string $model = LegalDocument::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-text';

    protected static ?string $navigationGroup = 'المحتوى القانوني';

    protected static ?string $navigationLabel = 'الوثائق القانونية';

    protected static ?string $modelLabel = 'وثيقة قانونية';

    protected static ?string $pluralModelLabel = 'الوثائق القانونية';

    protected static ?int $navigationSort = 1;

    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function canCreate(): bool
    {
        return static::canAccess();
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('البيانات الأساسية')
                    ->schema([
                        Forms\Components\Select::make('type')
                            ->label('النوع')
                            ->options(LegalDocumentType::options())
                            ->required()
                            ->disabled(fn (?LegalDocument $record): bool => $record !== null),
                        Forms\Components\TextInput::make('title')
                            ->label('العنوان')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('subtitle')
                            ->label('الوصف المختصر')
                            ->maxLength(255),
                        Forms\Components\Textarea::make('summary')
                            ->label('ملخص (اختياري)')
                            ->rows(2)
                            ->columnSpanFull(),
                        Forms\Components\TextInput::make('version')
                            ->label('رقم الإصدار')
                            ->required()
                            ->maxLength(32)
                            ->helperText('مثال: 1.0 أو 2.1'),
                        Forms\Components\Select::make('language')
                            ->label('اللغة')
                            ->options(['ar' => 'العربية', 'en' => 'English'])
                            ->default('ar')
                            ->required(),
                        Forms\Components\DateTimePicker::make('effective_at')
                            ->label('تاريخ السريان')
                            ->helperText('يُستخدم عند النشر إذا تُرك فارغًا'),
                        Forms\Components\Toggle::make('requires_acceptance')
                            ->label('يتطلب موافقة المستخدم')
                            ->helperText('فعّله للتغييرات الجوهرية في الشروط'),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('الأقسام')
                    ->schema([
                        Forms\Components\Repeater::make('sections')
                            ->label('أقسام الوثيقة')
                            ->schema([
                                Forms\Components\TextInput::make('id')
                                    ->label('المعرف')
                                    ->required()
                                    ->maxLength(64)
                                    ->helperText('مثال: introduction'),
                                Forms\Components\TextInput::make('title')
                                    ->label('عنوان القسم')
                                    ->required()
                                    ->maxLength(255),
                                Forms\Components\TextInput::make('icon')
                                    ->label('أيقونة Material')
                                    ->default('article_outlined')
                                    ->maxLength(64),
                                Forms\Components\Repeater::make('paragraphs')
                                    ->label('فقرات')
                                    ->simple(
                                        Forms\Components\Textarea::make('paragraph')
                                            ->required()
                                            ->rows(2),
                                    )
                                    ->defaultItems(0)
                                    ->columnSpanFull(),
                                Forms\Components\Repeater::make('bullet_points')
                                    ->label('نقاط')
                                    ->simple(
                                        Forms\Components\TextInput::make('point')
                                            ->required(),
                                    )
                                    ->defaultItems(0)
                                    ->columnSpanFull(),
                                Forms\Components\Repeater::make('subsections')
                                    ->label('أقسام فرعية')
                                    ->schema([
                                        Forms\Components\TextInput::make('title')
                                            ->label('العنوان')
                                            ->required(),
                                        Forms\Components\Repeater::make('items')
                                            ->label('عناصر')
                                            ->simple(
                                                Forms\Components\TextInput::make('item')
                                                    ->required(),
                                            )
                                            ->defaultItems(0),
                                    ])
                                    ->defaultItems(0)
                                    ->columnSpanFull(),
                            ])
                            ->defaultItems(1)
                            ->columnSpanFull()
                            ->collapsible()
                            ->itemLabel(fn (array $state): ?string => $state['title'] ?? null),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('type')
                    ->label('النوع')
                    ->formatStateUsing(fn (LegalDocumentType $state): string => $state->label())
                    ->badge(),
                Tables\Columns\TextColumn::make('version')
                    ->label('الإصدار')
                    ->searchable(),
                Tables\Columns\TextColumn::make('language')
                    ->label('اللغة'),
                Tables\Columns\TextColumn::make('status')
                    ->label('الحالة')
                    ->formatStateUsing(fn (LegalDocumentStatus $state): string => $state->label())
                    ->badge()
                    ->color(fn (LegalDocumentStatus $state): string => match ($state) {
                        LegalDocumentStatus::Draft => 'gray',
                        LegalDocumentStatus::Published => 'success',
                        LegalDocumentStatus::Superseded => 'warning',
                    }),
                Tables\Columns\IconColumn::make('requires_acceptance')
                    ->label('موافقة')
                    ->boolean(),
                Tables\Columns\TextColumn::make('published_at')
                    ->label('تاريخ النشر')
                    ->dateTime('Y-m-d H:i')
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('updated_at')
                    ->label('آخر تحديث')
                    ->since(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('type')
                    ->label('النوع')
                    ->options(LegalDocumentType::options()),
                Tables\Filters\SelectFilter::make('status')
                    ->label('الحالة')
                    ->options(LegalDocumentStatus::options()),
                Tables\Filters\SelectFilter::make('language')
                    ->label('اللغة')
                    ->options(['ar' => 'العربية', 'en' => 'English']),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make()
                    ->visible(fn (LegalDocument $record): bool => $record->isDraft()),
            ])
            ->bulkActions([]);
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                Infolists\Components\Section::make('معلومات النسخة')
                    ->schema([
                        Infolists\Components\TextEntry::make('type')
                            ->label('النوع')
                            ->formatStateUsing(fn (LegalDocumentType $state): string => $state->label()),
                        Infolists\Components\TextEntry::make('version')
                            ->label('الإصدار'),
                        Infolists\Components\TextEntry::make('status')
                            ->label('الحالة')
                            ->formatStateUsing(fn (LegalDocumentStatus $state): string => $state->label()),
                        Infolists\Components\TextEntry::make('language')
                            ->label('اللغة'),
                        Infolists\Components\IconEntry::make('requires_acceptance')
                            ->label('يتطلب موافقة')
                            ->boolean(),
                        Infolists\Components\TextEntry::make('published_at')
                            ->label('تاريخ النشر')
                            ->dateTime('Y-m-d H:i'),
                        Infolists\Components\TextEntry::make('effective_at')
                            ->label('تاريخ السريان')
                            ->dateTime('Y-m-d H:i'),
                    ])
                    ->columns(3),
                Infolists\Components\Section::make('المحتوى')
                    ->schema([
                        Infolists\Components\TextEntry::make('title')
                            ->label('العنوان'),
                        Infolists\Components\TextEntry::make('subtitle')
                            ->label('الوصف'),
                        Infolists\Components\RepeatableEntry::make('sections')
                            ->label('الأقسام')
                            ->schema([
                                Infolists\Components\TextEntry::make('title')
                                    ->label('القسم'),
                                Infolists\Components\TextEntry::make('paragraphs')
                                    ->label('فقرات')
                                    ->listWithLineBreaks()
                                    ->bulleted(),
                            ])
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListLegalDocuments::route('/'),
            'create' => Pages\CreateLegalDocument::route('/create'),
            'edit' => Pages\EditLegalDocument::route('/{record}/edit'),
            'view' => Pages\ViewLegalDocument::route('/{record}'),
        ];
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery();
    }
}
