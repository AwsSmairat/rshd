<?php

namespace App\Services;

use App\Enums\SupportTicketStatus;
use App\Models\SupportMessage;
use App\Models\SupportTicket;
use App\Models\User;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TechnicalSupportService
{
    public function openTicketForStudent(User $student): ?SupportTicket
    {
        return SupportTicket::query()
            ->where('student_id', $student->id)
            ->whereIn('status', [
                SupportTicketStatus::Pending->value,
                SupportTicketStatus::Active->value,
            ])
            ->with(['messages.sender', 'assignedAdmin'])
            ->latest('updated_at')
            ->first();
    }

    /**
     * @return array{ticket: SupportTicket, message: SupportMessage}
     */
    public function sendStudentMessage(User $student, string $body): array
    {
        $body = trim($body);

        if (mb_strlen($body) < 3) {
            throw ValidationException::withMessages([
                'message' => ['يجب أن تكون الرسالة 3 أحرف على الأقل.'],
            ]);
        }

        return DB::transaction(function () use ($student, $body): array {
            $ticket = SupportTicket::query()
                ->where('student_id', $student->id)
                ->whereIn('status', [
                    SupportTicketStatus::Pending->value,
                    SupportTicketStatus::Active->value,
                ])
                ->lockForUpdate()
                ->first();

            if ($ticket === null) {
                $ticket = SupportTicket::query()->create([
                    'student_id' => $student->id,
                    'status' => SupportTicketStatus::Pending,
                ]);
            }

            $message = SupportMessage::query()->create([
                'support_ticket_id' => $ticket->id,
                'sender_id' => $student->id,
                'body' => $body,
            ]);

            $ticket->touch();

            return [
                'ticket' => $ticket->fresh(['messages.sender', 'assignedAdmin']),
                'message' => $message->load('sender'),
            ];
        });
    }

    /** @return Collection<int, SupportTicket> */
    public function pendingTicketsForAdmins(): Collection
    {
        return SupportTicket::query()
            ->where('status', SupportTicketStatus::Pending)
            ->whereNull('assigned_admin_id')
            ->with(['student', 'messages' => fn ($query) => $query->latest()->limit(1)])
            ->latest('updated_at')
            ->get();
    }

    /** @return Collection<int, SupportTicket> */
    public function activeTicketsForAdmin(User $admin): Collection
    {
        return SupportTicket::query()
            ->where('status', SupportTicketStatus::Active)
            ->where('assigned_admin_id', $admin->id)
            ->with(['student', 'messages' => fn ($query) => $query->latest()->limit(1)])
            ->latest('updated_at')
            ->get();
    }

    public function findTicketForAdmin(User $admin, int $ticketId): SupportTicket
    {
        $ticket = SupportTicket::query()
            ->with(['student', 'assignedAdmin', 'messages.sender'])
            ->findOrFail($ticketId);

        if ($ticket->status === SupportTicketStatus::Pending && $ticket->assigned_admin_id === null) {
            return $ticket;
        }

        if ($ticket->status === SupportTicketStatus::Active
            && $ticket->assigned_admin_id === $admin->id) {
            return $ticket;
        }

        throw new ModelNotFoundException('Support ticket not accessible.');
    }

    public function acceptTicket(User $admin, SupportTicket $ticket): SupportTicket
    {
        if (! $admin->isAdmin()) {
            throw ValidationException::withMessages([
                'ticket' => ['غير مصرح لك بقبول هذه المحادثة.'],
            ]);
        }

        return DB::transaction(function () use ($admin, $ticket): SupportTicket {
            $locked = SupportTicket::query()
                ->whereKey($ticket->id)
                ->where('status', SupportTicketStatus::Pending)
                ->whereNull('assigned_admin_id')
                ->lockForUpdate()
                ->first();

            if ($locked === null) {
                throw ValidationException::withMessages([
                    'ticket' => ['تم قبول هذه المحادثة من قبل مسؤول آخر.'],
                ]);
            }

            $locked->update([
                'status' => SupportTicketStatus::Active,
                'assigned_admin_id' => $admin->id,
                'accepted_at' => now(),
            ]);

            return $locked->fresh(['student', 'assignedAdmin', 'messages.sender']);
        });
    }

    public function sendAdminMessage(User $admin, SupportTicket $ticket, string $body): SupportMessage
    {
        $body = trim($body);

        if (mb_strlen($body) < 1) {
            throw ValidationException::withMessages([
                'message' => ['الرسالة مطلوبة.'],
            ]);
        }

        if ($ticket->status !== SupportTicketStatus::Active
            || $ticket->assigned_admin_id !== $admin->id) {
            throw ValidationException::withMessages([
                'ticket' => ['لا يمكن الرد على هذه المحادثة.'],
            ]);
        }

        $message = SupportMessage::query()->create([
            'support_ticket_id' => $ticket->id,
            'sender_id' => $admin->id,
            'body' => $body,
        ]);

        $ticket->touch();

        return $message->load('sender');
    }

    public function closeTicket(User $admin, SupportTicket $ticket): SupportTicket
    {
        if ($ticket->status !== SupportTicketStatus::Active
            || $ticket->assigned_admin_id !== $admin->id) {
            throw ValidationException::withMessages([
                'ticket' => ['لا يمكن إنهاء هذه المحادثة.'],
            ]);
        }

        $ticket->update([
            'status' => SupportTicketStatus::Closed,
            'closed_at' => now(),
        ]);

        return $ticket->fresh(['student', 'assignedAdmin', 'messages.sender']);
    }

    /**
     * @return array<string, mixed>
     */
    public function formatTicketForStudent(User $student, ?SupportTicket $ticket): array
    {
        if ($ticket === null) {
            return [
                'ticket' => null,
                'messages' => [],
            ];
        }

        return [
            'ticket' => [
                'id' => $ticket->id,
                'status' => $ticket->status->value,
                'status_label' => $ticket->status->label(),
                'assigned_admin_name' => $ticket->assignedAdmin?->name,
                'created_at' => $ticket->created_at?->toIso8601String(),
                'accepted_at' => $ticket->accepted_at?->toIso8601String(),
                'closed_at' => $ticket->closed_at?->toIso8601String(),
            ],
            'messages' => $ticket->messages->map(
                fn (SupportMessage $message): array => $this->formatMessageForUser($student, $message),
            )->values()->all(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function formatMessageForUser(User $viewer, SupportMessage $message): array
    {
        return [
            'id' => $message->id,
            'body' => $message->body,
            'sender_name' => $message->sender?->name,
            'is_mine' => $message->sender_id === $viewer->id,
            'created_at' => $message->created_at?->toIso8601String(),
        ];
    }
}
