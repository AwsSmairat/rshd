<?php

namespace App\Filament\Pages;

use App\Models\SupportMessage;
use App\Models\SupportTicket;
use App\Models\User;
use App\Services\TechnicalSupportService;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class TechnicalSupport extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-lifebuoy';

    protected static ?string $navigationGroup = 'التواصل';

    protected static ?string $navigationLabel = 'الدعم الفني';

    protected static ?string $title = 'الدعم الفني';

    protected static ?int $navigationSort = 3;

    protected static string $view = 'filament.pages.technical-support';

    public ?string $loadError = null;

    /** @var Collection<int, SupportTicket> */
    public Collection $pendingTickets;

    /** @var Collection<int, SupportTicket> */
    public Collection $activeTickets;

    public ?int $selectedTicketId = null;

    public ?SupportTicket $selectedTicket = null;

    public string $replyBody = '';

    public ?string $replyError = null;

    public function mount(): void
    {
        $this->pendingTickets = collect();
        $this->activeTickets = collect();
        $this->loadTickets();
    }

    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public static function shouldRegisterNavigation(): bool
    {
        return static::canAccess();
    }

    public function getTitle(): string|Htmlable
    {
        return 'الدعم الفني';
    }

    public function getHeading(): string|Htmlable
    {
        return '';
    }

    public function loadTickets(): void
    {
        $admin = $this->authUser();

        if ($admin === null) {
            $this->pendingTickets = collect();
            $this->activeTickets = collect();

            return;
        }

        try {
            $service = app(TechnicalSupportService::class);
            $this->pendingTickets = $service->pendingTicketsForAdmins();
            $this->activeTickets = $service->activeTicketsForAdmin($admin);

            if ($this->selectedTicketId !== null) {
                $this->refreshSelectedTicket();
            }
        } catch (\Throwable $exception) {
            report($exception);
            $this->loadError = 'تعذر تحميل محادثات الدعم الفني.';
            $this->pendingTickets = collect();
            $this->activeTickets = collect();
        }
    }

    public function selectTicket(int $ticketId): void
    {
        $this->selectedTicketId = $ticketId;
        $this->replyBody = '';
        $this->replyError = null;
        $this->refreshSelectedTicket();
    }

    public function clearSelection(): void
    {
        $this->selectedTicketId = null;
        $this->selectedTicket = null;
        $this->replyBody = '';
        $this->replyError = null;
    }

    public function acceptTicket(TechnicalSupportService $support): void
    {
        $admin = $this->authUser();

        if ($admin === null || $this->selectedTicket === null) {
            return;
        }

        try {
            $this->selectedTicket = $support->acceptTicket($admin, $this->selectedTicket);
            $this->selectedTicketId = $this->selectedTicket->id;

            Notification::make()
                ->title('تم قبول المحادثة')
                ->body('أصبحت مسؤولاً عن هذه المحادثة.')
                ->success()
                ->send();
        } catch (ValidationException $exception) {
            Notification::make()
                ->title('تعذر قبول المحادثة')
                ->body(collect($exception->errors())->flatten()->first() ?? 'حاول مرة أخرى.')
                ->danger()
                ->send();
            $this->clearSelection();
        } catch (\Throwable $exception) {
            report($exception);
            Notification::make()
                ->title('تعذر قبول المحادثة')
                ->danger()
                ->send();
        }

        $this->loadTickets();
    }

    public function sendReply(TechnicalSupportService $support): void
    {
        $this->replyError = null;
        $admin = $this->authUser();

        if ($admin === null || $this->selectedTicket === null) {
            return;
        }

        try {
            $support->sendAdminMessage($admin, $this->selectedTicket, $this->replyBody);
            $this->replyBody = '';
            $this->refreshSelectedTicket();
            $this->loadTickets();
        } catch (ValidationException $exception) {
            $this->replyError = collect($exception->errors())->flatten()->first()
                ?? 'تعذر إرسال الرد.';
        } catch (\Throwable $exception) {
            report($exception);
            $this->replyError = 'تعذر إرسال الرد.';
        }
    }

    public function closeTicket(TechnicalSupportService $support): void
    {
        $admin = $this->authUser();

        if ($admin === null || $this->selectedTicket === null) {
            return;
        }

        try {
            $support->closeTicket($admin, $this->selectedTicket);

            Notification::make()
                ->title('تم إنهاء المحادثة')
                ->success()
                ->send();

            $this->clearSelection();
            $this->loadTickets();
        } catch (ValidationException $exception) {
            Notification::make()
                ->title('تعذر إنهاء المحادثة')
                ->body(collect($exception->errors())->flatten()->first() ?? 'حاول مرة أخرى.')
                ->danger()
                ->send();
        } catch (\Throwable $exception) {
            report($exception);
            Notification::make()
                ->title('تعذر إنهاء المحادثة')
                ->danger()
                ->send();
        }
    }

    public function canAcceptSelected(): bool
    {
        return $this->selectedTicket !== null
            && $this->selectedTicket->status->value === 'pending'
            && $this->selectedTicket->assigned_admin_id === null;
    }

    public function canReplyToSelected(): bool
    {
        $admin = $this->authUser();

        return $this->selectedTicket !== null
            && $this->selectedTicket->status->value === 'active'
            && $this->selectedTicket->assigned_admin_id === $admin?->id;
    }

    public function previewMessage(SupportTicket $ticket): ?string
    {
        /** @var SupportMessage|null $message */
        $message = $ticket->messages->first();

        return $message?->body;
    }

    protected function refreshSelectedTicket(): void
    {
        $admin = $this->authUser();

        if ($admin === null || $this->selectedTicketId === null) {
            $this->selectedTicket = null;

            return;
        }

        try {
            $this->selectedTicket = app(TechnicalSupportService::class)
                ->findTicketForAdmin($admin, $this->selectedTicketId);
        } catch (ModelNotFoundException) {
            $this->clearSelection();
        }
    }

    protected function authUser(): ?User
    {
        /** @var User|null */
        return Auth::user();
    }
}
