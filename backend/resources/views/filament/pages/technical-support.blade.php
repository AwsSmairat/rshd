<div class="rshd-instructor-page" wire:init="loadTickets">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => 'الدعم الفني',
        'subtitle' => 'محادثات الطلاب — تظهر للجميع حتى يقبلها أحد المسؤولين',
    ])

    <div wire:loading.flex wire:target="loadTickets,acceptTicket,sendReply,closeTicket" class="rshd-dashboard-loading">
        <span>جاري التحميل...</span>
    </div>

    @if ($this->loadError)
        <div class="rshd-alert rshd-alert--danger">{{ $this->loadError }}</div>
    @endif

    <div class="rshd-support-layout">
        <aside class="rshd-support-sidebar">
            <article class="rshd-panel rshd-panel--page">
                <div class="rshd-panel__header">
                    <h2>بانتظار القبول</h2>
                    @if ($this->pendingTickets->isNotEmpty())
                        <span class="rshd-panel__count">{{ $this->pendingTickets->count() }}</span>
                    @endif
                </div>
                <div class="rshd-panel__body">
                    @if ($this->pendingTickets->isEmpty())
                        <div class="rshd-empty">لا توجد محادثات بانتظار القبول.</div>
                    @else
                        <div class="rshd-support-list">
                            @foreach ($this->pendingTickets as $ticket)
                                <button
                                    type="button"
                                    @class([
                                        'rshd-support-item',
                                        'rshd-support-item--active' => $this->selectedTicketId === $ticket->id,
                                    ])
                                    wire:click="selectTicket({{ $ticket->id }})"
                                    wire:key="pending-{{ $ticket->id }}"
                                >
                                    <strong>{{ $ticket->student?->name ?? 'طالب' }}</strong>
                                    <span>{{ optional($ticket->updated_at)->locale('ar')->diffForHumans() }}</span>
                                    @if ($preview = $this->previewMessage($ticket))
                                        <p>{{ \Illuminate\Support\Str::limit($preview, 80) }}</p>
                                    @endif
                                </button>
                            @endforeach
                        </div>
                    @endif
                </div>
            </article>

            <article class="rshd-panel rshd-panel--page">
                <div class="rshd-panel__header">
                    <h2>محادثاتي الجارية</h2>
                    @if ($this->activeTickets->isNotEmpty())
                        <span class="rshd-panel__count">{{ $this->activeTickets->count() }}</span>
                    @endif
                </div>
                <div class="rshd-panel__body">
                    @if ($this->activeTickets->isEmpty())
                        <div class="rshd-empty">لا توجد محادثات جارية مخصصة لك.</div>
                    @else
                        <div class="rshd-support-list">
                            @foreach ($this->activeTickets as $ticket)
                                <button
                                    type="button"
                                    @class([
                                        'rshd-support-item',
                                        'rshd-support-item--active' => $this->selectedTicketId === $ticket->id,
                                    ])
                                    wire:click="selectTicket({{ $ticket->id }})"
                                    wire:key="active-{{ $ticket->id }}"
                                >
                                    <strong>{{ $ticket->student?->name ?? 'طالب' }}</strong>
                                    <span>{{ optional($ticket->updated_at)->locale('ar')->diffForHumans() }}</span>
                                    @if ($preview = $this->previewMessage($ticket))
                                        <p>{{ \Illuminate\Support\Str::limit($preview, 80) }}</p>
                                    @endif
                                </button>
                            @endforeach
                        </div>
                    @endif
                </div>
            </article>
        </aside>

        <section class="rshd-support-chat">
            <article class="rshd-panel rshd-panel--page">
                @if ($this->selectedTicket === null)
                    <div class="rshd-panel__body">
                        <div class="rshd-empty">اختر محادثة من القائمة لعرض الرسائل.</div>
                    </div>
                @else
                    <div class="rshd-panel__header">
                        <div>
                            <h2>{{ $this->selectedTicket->student?->name ?? 'طالب' }}</h2>
                            <span class="rshd-badge rshd-badge--success">
                                {{ $this->selectedTicket->status->label() }}
                            </span>
                        </div>
                        <div class="rshd-support-chat__actions">
                            @if ($this->canAcceptSelected())
                                <button
                                    type="button"
                                    class="rshd-grade-btn"
                                    wire:click="acceptTicket"
                                    wire:loading.attr="disabled"
                                    wire:target="acceptTicket"
                                >
                                    قبول المحادثة
                                </button>
                            @endif
                            @if ($this->canReplyToSelected())
                                <button
                                    type="button"
                                    class="rshd-grade-btn rshd-grade-btn--danger"
                                    wire:click="closeTicket"
                                    wire:loading.attr="disabled"
                                    wire:target="closeTicket"
                                >
                                    إنهاء المحادثة
                                </button>
                            @endif
                        </div>
                    </div>

                    <div class="rshd-panel__body rshd-support-chat__body">
                        <div class="rshd-support-messages">
                            @foreach ($this->selectedTicket->messages as $message)
                                @php
                                    $isAdmin = $message->sender_id === $this->selectedTicket->assigned_admin_id
                                        || ($message->sender?->isAdmin() ?? false);
                                @endphp
                                <article
                                    @class([
                                        'rshd-support-message',
                                        'rshd-support-message--admin' => $isAdmin,
                                        'rshd-support-message--student' => ! $isAdmin,
                                    ])
                                    wire:key="msg-{{ $message->id }}"
                                >
                                    <div class="rshd-support-message__meta">
                                        <strong>{{ $message->sender?->name ?? 'مستخدم' }}</strong>
                                        <span>{{ optional($message->created_at)->locale('ar')->diffForHumans() }}</span>
                                    </div>
                                    <div class="rshd-message-item__bubble">
                                        <p>{{ $message->body }}</p>
                                    </div>
                                </article>
                            @endforeach
                        </div>

                        @if ($this->canReplyToSelected())
                            <div class="rshd-message-reply">
                                <label for="support-reply-body">اكتب ردك للطالب</label>
                                <textarea
                                    id="support-reply-body"
                                    wire:model.defer="replyBody"
                                    rows="4"
                                    maxlength="2000"
                                    placeholder="اكتب رسالتك هنا..."
                                ></textarea>
                                @if ($this->replyError)
                                    <p class="rshd-message-reply__error">{{ $this->replyError }}</p>
                                @endif
                                <div class="rshd-message-reply__actions">
                                    <button
                                        type="button"
                                        class="rshd-grade-btn"
                                        wire:click="sendReply"
                                        wire:loading.attr="disabled"
                                        wire:target="sendReply"
                                    >
                                        <span wire:loading.remove wire:target="sendReply">إرسال</span>
                                        <span wire:loading wire:target="sendReply">جاري الإرسال...</span>
                                    </button>
                                </div>
                            </div>
                        @elseif ($this->canAcceptSelected())
                            <div class="rshd-alert">
                                اضغط «قبول المحادثة» لتصبح مسؤولاً عنها وتختفي من باقي المسؤولين.
                            </div>
                        @endif
                    </div>
                @endif
            </article>
        </section>
    </div>

    <style>
        .rshd-support-layout {
            display: grid;
            grid-template-columns: minmax(260px, 320px) minmax(0, 1fr);
            gap: 1rem;
            align-items: start;
        }

        .rshd-support-sidebar {
            display: flex;
            flex-direction: column;
            gap: 1rem;
        }

        .rshd-support-list {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }

        .rshd-support-item {
            display: flex;
            flex-direction: column;
            align-items: flex-start;
            gap: 0.25rem;
            width: 100%;
            padding: 0.75rem;
            border: 1px solid rgba(15, 23, 42, 0.08);
            border-radius: 0.75rem;
            background: #fff;
            text-align: right;
            cursor: pointer;
        }

        .rshd-support-item--active {
            border-color: #1e3a5f;
            background: rgba(30, 58, 95, 0.05);
        }

        .rshd-support-item span {
            font-size: 0.75rem;
            color: #64748b;
        }

        .rshd-support-item p {
            margin: 0;
            font-size: 0.8125rem;
            color: #475569;
            line-height: 1.5;
        }

        .rshd-support-chat__actions {
            display: flex;
            gap: 0.5rem;
            flex-wrap: wrap;
        }

        .rshd-support-chat__body {
            display: flex;
            flex-direction: column;
            gap: 1rem;
            min-height: 420px;
        }

        .rshd-support-messages {
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            flex: 1;
            overflow-y: auto;
            max-height: 480px;
        }

        .rshd-support-message__meta {
            display: flex;
            justify-content: space-between;
            gap: 0.5rem;
            margin-bottom: 0.25rem;
            font-size: 0.75rem;
            color: #64748b;
        }

        .rshd-support-message--admin .rshd-message-item__bubble {
            background: rgba(30, 58, 95, 0.08);
        }

        @media (max-width: 960px) {
            .rshd-support-layout {
                grid-template-columns: 1fr;
            }
        }
    </style>
</div>
