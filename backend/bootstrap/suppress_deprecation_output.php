<?php

/**
 * Prevent PHP deprecation HTML from polluting JSON API responses (PHP 8.5+).
 * Errors are still logged by Laravel; only browser/client output is suppressed.
 */
ini_set('display_errors', '0');
error_reporting(E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED);
