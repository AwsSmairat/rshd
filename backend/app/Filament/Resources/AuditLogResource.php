<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AuditLogResource\Pages;
use App\Models\AuditLog;
use App\Support\AuditActionCatalog;
use Filament\Forms\Components\DatePicker;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class AuditLogResource extends Resource
{
    protected static ?string $model = AuditLog::class;

    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-list';

    protected static ?string $navigationGroup = 'النظام';

    protected static ?string $navigationLabel = 'سجل النشاطات';

    protected static ?string $modelLabel = 'سجل';

    protected static ?string $pluralModelLabel = 'سجل النشاطات';

    protected static ?int $navigationSort = 3;

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

    public static function canEdit($record): bool
    {
        return false;
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                Infolists\Components\Section::make('تفاصيل النشاط')
                    ->schema([
                        Infolists\Components\TextEntry::make('created_at')
                            ->label('التاريخ')
                            ->dateTime(),
                        Infolists\Components\TextEntry::make('user.name')
                            ->label('المستخدم')
                            ->placeholder('—'),
                        Infolists\Components\TextEntry::make('action')
                            ->label('الإجراء')
                            ->formatStateUsing(fn (string $state): string => AuditActionCatalog::actionLabel($state))
                            ->badge()
                            ->color(fn (AuditLog $record): string => AuditActionCatalog::actionColor($record->action)),
                        Infolists\Components\TextEntry::make('model_type')
                            ->label('النموذج')
                            ->formatStateUsing(fn (AuditLog $record): string => AuditActionCatalog::modelLabel($record)),
                        Infolists\Components\TextEntry::make('model_id')
                            ->label('معرّف السجل')
                            ->placeholder('—'),
                        Infolists\Components\TextEntry::make('description')
                            ->label('الوصف')
                            ->formatStateUsing(fn (AuditLog $record): string => AuditActionCatalog::displayDescription($record))
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->emptyStateHeading('لا توجد نشاطات مسجّلة')
            ->emptyStateDescription('ستظهر هنا الإجراءات التي يسجّلها النظام عند تفعيل سجل النشاطات من الإعدادات.')
            ->emptyStateIcon('heroicon-o-clipboard-document-list')
            ->columns([
                Tables\Columns\TextColumn::make('created_at')
                    ->label('التاريخ')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
                Tables\Columns\TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('action')
                    ->label('الإجراء')
                    ->formatStateUsing(fn (string $state): string => AuditActionCatalog::actionLabel($state))
                    ->badge()
                    ->color(fn (AuditLog $record): string => AuditActionCatalog::actionColor($record->action))
                    ->searchable(),
                Tables\Columns\TextColumn::make('description')
                    ->label('الوصف')
                    ->formatStateUsing(fn (AuditLog $record): string => AuditActionCatalog::displayDescription($record))
                    ->limit(80)
                    ->wrap()
                    ->searchable(),
                Tables\Columns\TextColumn::make('model_type')
                    ->label('النموذج')
                    ->formatStateUsing(fn (AuditLog $record): string => AuditActionCatalog::modelLabel($record))
                    ->placeholder('—'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('category')
                    ->label('الفئة')
                    ->options(AuditActionCatalog::categoryOptions())
                    ->query(function (Builder $query, array $data): Builder {
                        $category = $data['value'] ?? null;

                        if (! filled($category)) {
                            return $query;
                        }

                        return $query->where(function (Builder $inner) use ($category): void {
                            foreach (self::actionsForCategory((string) $category) as $action) {
                                $inner->orWhere('action', $action);
                            }

                            foreach (self::prefixesForCategory((string) $category) as $prefix) {
                                $inner->orWhere('action', 'like', $prefix.'%');
                            }
                        });
                    }),
                Tables\Filters\Filter::make('created_at')
                    ->label('التاريخ')
                    ->form([
                        DatePicker::make('from')
                            ->label('من'),
                        DatePicker::make('until')
                            ->label('إلى'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when($data['from'] ?? null, fn (Builder $q, $date): Builder => $q->whereDate('created_at', '>=', $date))
                            ->when($data['until'] ?? null, fn (Builder $q, $date): Builder => $q->whereDate('created_at', '<=', $date));
                    }),
            ])
            ->actions([
                Tables\Actions\ViewAction::make()
                    ->label('عرض'),
            ])
            ->bulkActions([]);
    }

    /**
     * @return list<string>
     */
    private static function actionsForCategory(string $category): array
    {
        return match ($category) {
            'settings' => ['settings.group.updated', 'maintenance.updated'],
            'auth' => ['register.created', 'login.success', 'login.failed', 'logout', 'instructor.password_set'],
            default => [],
        };
    }

    /**
     * @return list<string>
     */
    private static function prefixesForCategory(string $category): array
    {
        return match ($category) {
            'users' => ['student.', 'admin.', 'instructor.'],
            'content' => ['announcement.', 'notification.'],
            'settings' => ['settings.'],
            'activation' => ['enrollment.'],
            'financial' => ['expense.'],
            'devices' => ['device.'],
            default => [],
        };
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAuditLogs::route('/'),
        ];
    }
}
