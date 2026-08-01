<?php

namespace App\Models;

use App\Enums\AccessStatus;
use App\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\Pivot;

class SubjectStudent extends Pivot
{
    protected $table = 'subject_students';

    public $incrementing = true;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'subject_id',
        'student_id',
        'activated_by',
        'payment_status',
        'sale_price',
        'paid_at',
        'access_status',
        'activated_at',
        'expires_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'payment_status' => PaymentStatus::class,
            'access_status' => AccessStatus::class,
            'sale_price' => 'decimal:2',
            'paid_at' => 'datetime',
            'activated_at' => 'datetime',
            'expires_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Subject, $this>
     */
    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function activatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'activated_by');
    }
}
