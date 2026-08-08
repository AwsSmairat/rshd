<?php

namespace App\Enums;

enum LessonFileStorageStatus: string
{
    case Pending = 'pending';
    case Ready = 'ready';
    case Failed = 'failed';
}
