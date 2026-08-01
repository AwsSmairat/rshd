<?php

namespace App\Filament\Resources;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Filament\Concerns\ChecksPlatformInstructorSettings;
use App\Filament\Concerns\HasInstructorScope;
use App\Filament\Resources\SubjectStudentResource\Pages;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Services\EnrollmentService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Actions\Action;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class SubjectStudentResource extends Resource
{
    use ChecksPlatformInstructorSettings;
    use HasInstructorScope;

    protected static ?string $model = SubjectStudent::class;

    protected static ?string $slug = 'enrollments';

    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-check';

    protected static ?string $navigationGroup = 'التعلم';

    protected static ?string $navigationLabel = 'طلبات التفعيل';

    protected static ?string $modelLabel = 'تفعيل مادة';

    protected static ?string $pluralModelLabel = 'طلبات التفعيل والتسجيلات';

    protected static ?int $navigationSort = 1;

    public static function canAccess(): bool
    {
        $user = auth()->user();

        if ($user?->isAdmin()) {
            return true;
        }

        if (! $user?->isInstructor()) {
            return false;
        }

        $settings = static::platformSettings();

        return $settings->enabled('allow_instructor_activate_students', 'payments')
            || $settings->enabled('allow_instructor_view_sale_price', 'payments');
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    public static function getEloquentQuery(): Builder
    {
        $query = parent::getEloquentQuery();
        $user = auth()->user();

        if ($user?->isAdmin()) {
            return $query;
        }

        return $query->whereHas('subject', fn (Builder $q) => $q->where('instructor_id', $user?->id));
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function canEdit(\Illuminate\Database\Eloquent\Model $record): bool
    {
        if (auth()->user()?->isAdmin()) {
            return true;
        }

        return static::platformSettings()->enabled('allow_instructor_activate_students', 'payments');
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
                                fn (Builder $query) => static::isAdmin()
                                    ? $query
                                    : $query->where('instructor_id', static::authUser()?->id),
                            )
                            ->searchable()
                            ->preload()
                            ->required()
                            ->live(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('الدفع والوصول')
                    ->schema([
                        Forms\Components\TextInput::make('sale_price')
                            ->label('سعر البيع')
                            ->numeric()
                            ->minValue(0)
                            ->suffix('د.أ')
                            ->helperText('يُحفظ وقت التفعيل. إذا تُرك فارغاً يُؤخذ من سعر المادة.')
                            ->visible(fn (): bool => auth()->user()?->isAdmin()
                                || static::platformSettings()->enabled('allow_instructor_view_sale_price', 'payments')),
                        Forms\Components\Select::make('payment_status')
                            ->label('حالة الدفع')
                            ->options(PaymentStatus::options())
                            ->default(PaymentStatus::Unpaid->value)
                            ->required(),
                        Forms\Components\Select::make('access_status')
                            ->label('حالة الوصول')
                            ->options(AccessStatus::options())
                            ->default(AccessStatus::Pending->value)
                            ->required(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make('سجل التفعيل')
                    ->schema([
                        Forms\Components\DateTimePicker::make('paid_at')
                            ->label('تاريخ الدفع'),
                        Forms\Components\DateTimePicker::make('activated_at')
                            ->label('تاريخ التفعيل'),
                        Forms\Components\DateTimePicker::make('expires_at')
                            ->label('تاريخ الانتهاء'),
                        Forms\Components\Select::make('activated_by')
                            ->label('تم التفعيل بواسطة')
                            ->relationship('activatedBy', 'name')
                            ->searchable()
                            ->disabled()
                            ->dehydrated(),
                    ])
                    ->columns(2)
                    ->collapsed(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->persistFiltersInSession()
            ->columns([
                Tables\Columns\TextColumn::make('student.name')
                    ->label('الطالب')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('subject.title')
                    ->label('المادة')
                    ->searchable()
                    ->sortable()
                    ->limit(30),
                Tables\Columns\TextColumn::make('subject.instructor.name')
                    ->label('المدرس')
                    ->sortable()
                    ->visible(fn (): bool => static::isAdmin())
                    ->toggleable(isToggledHiddenByDefault: false),
                Tables\Columns\TextColumn::make('sale_price')
                    ->label('سعر البيع')
                    ->formatStateUsing(fn (?string $state): string => $state !== null
                        ? number_format((float) $state, 3).' د.أ'
                        : '—')
                    ->sortable()
                    ->visible(fn (): bool => auth()->user()?->isAdmin()
                        || static::platformSettings()->enabled('allow_instructor_view_sale_price', 'payments')),
                Tables\Columns\TextColumn::make('payment_status')
                    ->label('الدفع')
                    ->badge()
                    ->formatStateUsing(fn (PaymentStatus|string|null $state): string => match ($state instanceof PaymentStatus ? $state : PaymentStatus::tryFrom((string) $state)) {
                        PaymentStatus::Paid => PaymentStatus::Paid->label(),
                        PaymentStatus::Unpaid => PaymentStatus::Unpaid->label(),
                        default => (string) $state,
                    })
                    ->color(fn (PaymentStatus|string|null $state): string => match ($state instanceof PaymentStatus ? $state : PaymentStatus::tryFrom((string) $state)) {
                        PaymentStatus::Paid => 'success',
                        PaymentStatus::Unpaid => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('access_status')
                    ->label('الوصول')
                    ->badge()
                    ->formatStateUsing(fn (AccessStatus|string|null $state): string => match ($state instanceof AccessStatus ? $state : AccessStatus::tryFrom((string) $state)) {
                        AccessStatus::Pending => AccessStatus::Pending->label(),
                        AccessStatus::Active => AccessStatus::Active->label(),
                        AccessStatus::Revoked => AccessStatus::Revoked->label(),
                        AccessStatus::Expired => AccessStatus::Expired->label(),
                        default => (string) $state,
                    })
                    ->color(fn (AccessStatus|string|null $state): string => match ($state instanceof AccessStatus ? $state : AccessStatus::tryFrom((string) $state)) {
                        AccessStatus::Pending => 'warning',
                        AccessStatus::Active => 'success',
                        AccessStatus::Revoked => 'danger',
                        AccessStatus::Expired => 'gray',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الطلب')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
                Tables\Columns\TextColumn::make('activated_at')
                    ->label('تاريخ التفعيل')
                    ->dateTime('Y-m-d H:i')
                    ->placeholder('—')
                    ->toggleable(),
                Tables\Columns\TextColumn::make('paid_at')
                    ->label('تاريخ الدفع')
                    ->dateTime('Y-m-d H:i')
                    ->placeholder('—')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('activatedBy.name')
                    ->label('تم بواسطة')
                    ->placeholder('—')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('request_state')
                    ->label('الحالة')
                    ->options([
                        'pending' => 'طلبات بانتظار التفعيل',
                        'active' => 'مفعّلة',
                        'all' => 'الكل',
                    ])
                    ->default('pending')
                    ->query(function (Builder $query, array $data): Builder {
                        $value = $data['value'] ?? 'pending';

                        return match ($value) {
                            'active' => $query
                                ->where('payment_status', PaymentStatus::Paid)
                                ->where('access_status', AccessStatus::Active),
                            'all' => $query,
                            default => $query->where(function (Builder $q): void {
                                $q->where('access_status', AccessStatus::Pending)
                                    ->orWhere(function (Builder $inner): void {
                                        $inner->where('payment_status', PaymentStatus::Unpaid)
                                            ->where('access_status', '!=', AccessStatus::Active);
                                    });
                            }),
                        };
                    }),
                Tables\Filters\SelectFilter::make('subject_id')
                    ->label('المادة')
                    ->relationship(
                        'subject',
                        'title',
                        fn (Builder $query) => static::isAdmin()
                            ? $query
                            : $query->where('instructor_id', static::authUser()?->id),
                    )
                    ->searchable()
                    ->preload(),
                Tables\Filters\SelectFilter::make('payment_status')
                    ->label('حالة الدفع')
                    ->options(PaymentStatus::options()),
                Tables\Filters\SelectFilter::make('access_status')
                    ->label('حالة الوصول')
                    ->options(AccessStatus::options()),
            ])
            ->actions([
                Action::make('activate')
                    ->label('تفعيل')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('تفعيل المادة للطالب')
                    ->modalDescription('سيتم تفعيل وصول الطالب للمادة وإشعاره.')
                    ->visible(function (SubjectStudent $record): bool {
                        if ($record->payment_status === PaymentStatus::Paid
                            && $record->access_status === AccessStatus::Active) {
                            return false;
                        }

                        $user = auth()->user();

                        if ($user?->isAdmin()) {
                            return true;
                        }

                        return static::platformSettings()->enabled('allow_instructor_activate_students', 'payments');
                    })
                    ->action(function (SubjectStudent $record): void {
                        /** @var User $admin */
                        $admin = auth()->user();
                        $record->loadMissing(['student', 'subject']);

                        if ($record->student === null || $record->subject === null) {
                            Notification::make()
                                ->title('تعذر التفعيل')
                                ->danger()
                                ->send();

                            return;
                        }

                        app(EnrollmentService::class)->activateStudent(
                            $record->student,
                            $record->subject,
                            $admin,
                        );

                        Notification::make()
                            ->title('تم تفعيل المادة للطالب')
                            ->success()
                            ->send();
                    }),
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('لا توجد طلبات تفعيل')
            ->emptyStateDescription('عندما يسجّل طالب لمادة أو يطلب شراءها، ستظهر الطلبات هنا. يمكنك أيضاً تفعيل مادة يدوياً من زر «تفعيل مادة لطالب».')
            ->emptyStateIcon('heroicon-o-clipboard-document-check');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSubjectStudents::route('/'),
            'create' => Pages\CreateSubjectStudent::route('/create'),
            'edit' => Pages\EditSubjectStudent::route('/{record}/edit'),
        ];
    }
}
