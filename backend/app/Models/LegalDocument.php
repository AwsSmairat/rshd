<?php

namespace App\Models;

use App\Enums\LegalDocumentStatus;
use App\Enums\LegalDocumentType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class LegalDocument extends Model
{
    protected $fillable = [
        'type',
        'title',
        'subtitle',
        'summary',
        'sections',
        'version',
        'language',
        'status',
        'requires_acceptance',
        'published_at',
        'effective_at',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'type' => LegalDocumentType::class,
            'status' => LegalDocumentStatus::class,
            'sections' => 'array',
            'requires_acceptance' => 'boolean',
            'published_at' => 'datetime',
            'effective_at' => 'datetime',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function acceptances(): HasMany
    {
        return $this->hasMany(LegalDocumentAcceptance::class);
    }

    public function isDraft(): bool
    {
        return $this->status === LegalDocumentStatus::Draft;
    }

    public function isPublished(): bool
    {
        return $this->status === LegalDocumentStatus::Published;
    }

    public function hasAcceptances(): bool
    {
        return $this->acceptances()->exists();
    }
}
