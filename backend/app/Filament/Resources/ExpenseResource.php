<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ExpenseResource\Pages;
use App\Models\Expense;
use App\Services\PlatformSettingsService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class ExpenseResource extends Resource
{
    protected static ?string $model = Expense::class;

    protected static ?string $navigationIcon = 'heroicon-o-banknotes';

    protected static ?string $navigationGroup = 'المحاسبة';

    protected static ?string $navigationLabel = 'المصاريف';

    protected static ?string $modelLabel = 'مصروف';

    protected static ?string $pluralModelLabel = 'المصاريف';

    protected static ?int $navigationSort = 1;

    public static function canAccess(): bool
    {
        $user = auth()->user();

        if ($user?->isAdmin()) {
            return true;
        }

        return $user?->isInstructor()
            && app(PlatformSettingsService::class)->enabled('instructor_can_view_accounting', 'instructors');
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function canEdit(Model $record): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function canDelete(Model $record): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    /**
     * @return array<string, string>
     */
    public static function categoryOptions(): array
    {
        return [
            'تسويق' => 'تسويق',
            'استضافة' => 'استضافة',
            'رواتب' => 'رواتب',
            'أدوات' => 'أدوات',
            'تصميم' => 'تصميم',
            'أخرى' => 'أخرى',
        ];
    }

    public static function categoryColor(?string $category): string
    {
        return match ($category) {
            'تسويق' => 'warning',
            'استضافة' => 'info',
            'رواتب' => 'success',
            'أدوات' => 'primary',
            'تصميم' => 'gray',
            'أخرى' => 'gray',
            default => 'gray',
        };
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('تفاصيل المصروف')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('عنوان المصروف')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('amount')
                            ->label('المبلغ')
                            ->numeric()
                            ->minValue(0.01)
                            ->step(0.01)
                            ->suffix('د.أ')
                            ->required(),
                        Forms\Components\Select::make('category')
                            ->label('التصنيف')
                            ->options(static::categoryOptions())
                            ->default('أخرى')
                            ->required()
                            ->searchable(),
                        Forms\Components\DatePicker::make('expense_date')
                            ->label('تاريخ المصروف')
                            ->default(now())
                            ->maxDate(now())
                            ->required(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('ملاحظات')
                    ->schema([
                        Forms\Components\Textarea::make('description')
                            ->label('ملاحظة المصروف')
                            ->rows(4)
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('expense_date', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable()
                    ->limit(35),
                Tables\Columns\TextColumn::make('amount')
                    ->label('المبلغ')
                    ->formatStateUsing(fn (?string $state): string => number_format((float) ($state ?? 0), 2).' د.أ')
                    ->sortable(),
                Tables\Columns\TextColumn::make('category')
                    ->label('التصنيف')
                    ->badge()
                    ->color(fn (?string $state): string => static::categoryColor($state))
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('expense_date')
                    ->label('التاريخ')
                    ->date('Y-m-d')
                    ->sortable(),
                Tables\Columns\TextColumn::make('description')
                    ->label('ملاحظة')
                    ->limit(30)
                    ->placeholder('—')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('createdBy.name')
                    ->label('أُضيف بواسطة')
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('category')
                    ->label('التصنيف')
                    ->options(static::categoryOptions()),
                Tables\Filters\Filter::make('this_month')
                    ->label('هذا الشهر')
                    ->query(fn (Builder $query): Builder => $query->whereBetween('expense_date', [
                        now()->startOfMonth()->toDateString(),
                        now()->endOfMonth()->toDateString(),
                    ])),
                Tables\Filters\Filter::make('this_year')
                    ->label('هذا العام')
                    ->query(fn (Builder $query): Builder => $query->whereBetween('expense_date', [
                        now()->startOfYear()->toDateString(),
                        now()->endOfYear()->toDateString(),
                    ])),
                Tables\Filters\Filter::make('date_range')
                    ->label('نطاق تاريخ')
                    ->form([
                        Forms\Components\DatePicker::make('from')
                            ->label('من تاريخ'),
                        Forms\Components\DatePicker::make('to')
                            ->label('إلى تاريخ'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when($data['from'] ?? null, fn (Builder $q, $date) => $q->whereDate('expense_date', '>=', $date))
                            ->when($data['to'] ?? null, fn (Builder $q, $date) => $q->whereDate('expense_date', '<=', $date));
                    }),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد مصاريف')
            ->emptyStateDescription('ابدأ بتسجيل أول مصروف من زر «إضافة مصروف».');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListExpenses::route('/'),
            'create' => Pages\CreateExpense::route('/create'),
            'edit' => Pages\EditExpense::route('/{record}/edit'),
        ];
    }
}
