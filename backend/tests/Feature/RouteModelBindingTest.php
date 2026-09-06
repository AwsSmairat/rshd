<?php

namespace Tests\Feature;

use Illuminate\Contracts\Routing\UrlRoutable;
use Illuminate\Support\Str;
use ReflectionMethod;
use ReflectionNamedType;
use Tests\TestCase;

/**
 * The lesson file routes used to be declared as files/{file} while the
 * controller signature asked for $lessonFile, so they only worked thanks to a
 * Route::bind() call at the top of routes/api.php. Production deploys run
 * php artisan route:cache, which never executes that file, so the binder was
 * silently dropped and every lesson file endpoint answered 500.
 */
class RouteModelBindingTest extends TestCase
{
    public function test_every_route_parameter_matches_its_controller_parameter(): void
    {
        $mismatches = [];

        foreach (app('router')->getRoutes() as $route) {
            $action = $route->getActionName();

            if (! str_contains($action, '@')) {
                continue;
            }

            [$class, $method] = explode('@', $action);

            if (! class_exists($class) || ! method_exists($class, $method)) {
                continue;
            }

            $routeParameters = $route->parameterNames();

            foreach ((new ReflectionMethod($class, $method))->getParameters() as $parameter) {
                $type = $parameter->getType();

                if (! $type instanceof ReflectionNamedType || $type->isBuiltin()) {
                    continue;
                }

                if (! is_subclass_of($type->getName(), UrlRoutable::class)) {
                    continue;
                }

                $name = $parameter->getName();

                if (in_array($name, $routeParameters, true) || in_array(Str::snake($name), $routeParameters, true)) {
                    continue;
                }

                $mismatches[] = sprintf(
                    '%s expects $%s but declares {%s}',
                    $route->uri(),
                    $name,
                    implode('}, {', $routeParameters),
                );
            }
        }

        $this->assertSame([], $mismatches, implode(PHP_EOL, $mismatches));
    }

    public function test_lesson_file_routes_resolve_without_a_custom_binder(): void
    {
        $this->assertNull(
            app('router')->getBindingCallback('file'),
            'Route::bind() in a route file is skipped once routes are cached; rely on implicit binding instead.',
        );
    }
}
