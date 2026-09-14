<?php

namespace Tests\Feature\Security;

use PHPUnit\Framework\Attributes\Group;
use Tests\TestCase;

/**
 * Placeholder anchor for Security test suite discovery.
 * Real regression tests are added incrementally per authorization-matrix.yaml gaps.
 */
#[Group('security')]
class SecuritySuitePlaceholderTest extends TestCase
{
    public function test_security_suite_is_registered(): void
    {
        $this->assertTrue(true);
    }
}
