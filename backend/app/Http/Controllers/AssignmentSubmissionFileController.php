<?php

namespace App\Http\Controllers;

use App\Models\AssignmentSubmission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Hands a student's submitted file to the staff who may grade it: the
 * subject's instructor, or an admin. The link is signed and short-lived, and
 * the viewer must also be signed in to the panel.
 */
class AssignmentSubmissionFileController extends Controller
{
    public function __invoke(Request $request, AssignmentSubmission $submission): StreamedResponse
    {
        $user = $request->user();
        abort_if($user === null, 403);

        $submission->loadMissing('assignment.subject');
        $allowed = $user->isAdmin()
            || ($user->isInstructor()
                && $submission->assignment?->subject?->instructor_id === $user->id);
        abort_unless($allowed, 403);

        $path = (string) $submission->file_path;
        abort_if($path === '' || ! Storage::disk('local')->exists($path), 404);

        // Always a download, never shown in the panel's own origin.
        return Storage::disk('local')->download($path, $submission->downloadName(), [
            'Cache-Control' => 'private, no-store, no-cache, must-revalidate',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }
}
