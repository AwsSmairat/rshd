<div class="rshd-instructor-page" wire:init="loadMessages">
    @include('filament.pages.instructor.partials.page-header', [
        'title' => 'الرسائل',
        'subtitle' => 'إشعاراتك ورسائل المنصة',
    ])

    <div wire:loading.flex wire:target="loadMessages,sendReply" class="rshd-dashboard-loading">
        <span>جاري تحميل الرسائل...</span>
    </div>

    @if ($this->loadError)
        <div class="rshd-alert rshd-alert--danger">{{ $this->loadError }}</div>
    @endif

    <article class="rshd-panel rshd-panel--page">
        <div class="rshd-panel__header">
            <h2>صندوق الوارد</h2>
            @if ($this->unreadCount() > 0)
                <span class="rshd-panel__count">{{ $this->unreadCount() }} غير مقروء</span>
            @endif
        </div>
        <div class="rshd-panel__body">
            @if ($this->messages->isEmpty() && ! $this->loadError)
                <div class="rshd-empty">
                    لا توجد رسائل أو إشعارات حالياً.
                    <a href="{{ $this->createAnnouncementUrl() }}">أرسل إعلاناً لطلابك</a>
                </div>
            @else
                <div class="rshd-messages-list">
                    @foreach ($this->messages as $message)
                        @php
                            $meta = $this->messageMeta($message);
                            $isStudentMessage = $message->type === \App\Enums\AppNotificationType::StudentMessage->value;
                        @endphp
                        <article
                            @class([
                                'rshd-message-item',
                                'rshd-message-item--student' => $isStudentMessage,
                                'rshd-message-item--unread' => ! $message->is_read,
                            ])
                            wire:key="msg-{{ $message->id }}"
                        >
                            <div class="rshd-message-item__top">
                                @if ($isStudentMessage)
                                    <div class="rshd-message-item__avatar" aria-hidden="true">
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                                            <path d="M20 21a8 8 0 0 0-16 0"/>
                                            <circle cx="12" cy="8" r="4"/>
                                        </svg>
                                    </div>
                                @endif

                                <div class="rshd-message-item__content">
                                    <div class="rshd-message-item__head">
                                        <div class="rshd-message-item__title-wrap">
                                            @if ($isStudentMessage && ! empty($meta['student_name']))
                                                <strong>{{ $meta['student_name'] }}</strong>
                                                @if (! empty($meta['subject_title']))
                                                    <span class="rshd-message-item__subject">{{ $meta['subject_title'] }}</span>
                                                @endif
                                            @else
                                                <strong>{{ $message->title }}</strong>
                                            @endif

                                            @if ($isStudentMessage)
                                                <span class="rshd-badge rshd-badge--success">رسالة طالب</span>
                                            @endif
                                        </div>
                                        <span>{{ optional($message->created_at)->locale('ar')->diffForHumans() }}</span>
                                    </div>

                                    @if ($message->body)
                                        <div class="rshd-message-item__bubble">
                                            <p>{{ $message->body }}</p>
                                        </div>
                                    @endif

                                    @if ($isStudentMessage && $this->replyingToId !== $message->id)
                                        <div class="rshd-message-item__actions">
                                            <button
                                                type="button"
                                                class="rshd-grade-btn"
                                                wire:click="startReply({{ $message->id }})"
                                            >
                                                رد
                                            </button>
                                        </div>
                                    @endif
                                </div>
                            </div>

                            @if ($this->replyingToId === $message->id)
                                <div class="rshd-message-reply">
                                    <label for="reply-body-{{ $message->id }}">اكتب ردك للطالب</label>
                                    <textarea
                                        id="reply-body-{{ $message->id }}"
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
                                            class="rshd-grade-btn rshd-grade-btn--outline"
                                            wire:click="cancelReply"
                                        >
                                            إلغاء
                                        </button>
                                        <button
                                            type="button"
                                            class="rshd-grade-btn"
                                            wire:click="sendReply"
                                            wire:loading.attr="disabled"
                                            wire:target="sendReply"
                                        >
                                            <span wire:loading.remove wire:target="sendReply">إرسال الرد</span>
                                            <span wire:loading wire:target="sendReply">جاري الإرسال...</span>
                                        </button>
                                    </div>
                                </div>
                            @endif
                        </article>
                    @endforeach
                </div>
            @endif
        </div>
    </article>
</div>
