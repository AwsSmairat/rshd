<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    public function test_root_shows_public_rshd_home_page(): void
    {
        $response = $this->get("/");

        $response
            ->assertOk()
            ->assertSee("التعليم يبدأ من هنا", false)
            ->assertSee("منصة RSHD الأكاديمية", false)
            ->assertSee("/admin/login", false)
            ->assertSee("index, follow, max-image-preview:large", false)
            ->assertSee("rel=\"canonical\"", false)
            ->assertDontSee("<title>Laravel</title>", false);
    }
}
