<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * The private "local" disk used to own the GET /storage/{path} route, so every
 * public disk URL (student avatars, assignment attachments) answered 403
 * whenever the public/storage symlink was absent.
 */
class PublicStorageServingTest extends TestCase
{
    public function test_storage_route_is_bound_to_the_public_disk(): void
    {
        $route = app('router')->getRoutes()->getByName('storage.public');

        $this->assertNotNull($route, 'The /storage route must serve the public disk.');
        $this->assertNull(
            app('router')->getRoutes()->getByName('storage.local'),
            'The private disk must not shadow public storage URLs.',
        );
    }

    public function test_public_disk_file_is_served_without_a_signature(): void
    {
        Storage::fake('public');
        Storage::disk('public')->put('student-avatars/avatar.jpg', 'binary-image-bytes');

        $response = $this->get('/storage/student-avatars/avatar.jpg');

        $response->assertOk();
        $this->assertSame('binary-image-bytes', $response->streamedContent());
    }

    public function test_missing_public_file_returns_not_found_instead_of_forbidden(): void
    {
        Storage::fake('public');

        $this->get('/storage/student-avatars/missing.jpg')->assertNotFound();
    }

    public function test_private_disk_contents_are_not_reachable_through_storage_urls(): void
    {
        Storage::fake('public');
        Storage::fake('local');
        Storage::disk('local')->put('lesson-files/secret.pdf', 'private-bytes');

        $this->get('/storage/lesson-files/secret.pdf')->assertNotFound();
    }
}
