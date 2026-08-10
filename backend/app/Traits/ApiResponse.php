<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;

trait ApiResponse
{
    protected function successResponse(
        mixed $data = null,
        ?string $message = null,
        int $status = 200,
        ?array $meta = null,
    ): JsonResponse {
        $payload = [
            'success' => true,
            'data' => $data,
        ];

        if ($message !== null) {
            $payload['message'] = $message;
        }

        if ($meta !== null) {
            $payload['meta'] = $meta;
        }

        return response()->json($payload, $status);
    }

    protected function successList(array $data, ?string $message = null, int $status = 200): JsonResponse
    {
        $total = count($data);

        return $this->successResponse($data, $message, $status, [
            'current_page' => 1,
            'last_page' => 1,
            'per_page' => $total > 0 ? $total : 15,
            'total' => $total,
        ]);
    }

    protected function successResource(JsonResource $resource, ?string $message = null, int $status = 200): JsonResponse
    {
        return $this->successResponse($resource->resolve(request()), $message, $status);
    }

    protected function successResourceList(
        AnonymousResourceCollection $collection,
        ?string $message = null,
        int $status = 200,
    ): JsonResponse {
        return $this->successList($collection->resolve(), $message, $status);
    }

    protected function errorResponse(
        string $message,
        int $status = 400,
        ?array $errors = null,
        ?string $errorCode = null,
    ): JsonResponse {
        $payload = [
            'success' => false,
            'message' => $message,
            'errors' => $errors ?? new \stdClass,
        ];

        if ($errorCode !== null) {
            $payload['error_code'] = $errorCode;
        }

        return response()->json($payload, $status);
    }

    protected function validationErrorResponse(
        string $message,
        array $errors,
        int $status = 422,
    ): JsonResponse {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors' => $errors,
        ], $status);
    }

    protected function unauthorizedResponse(?string $message = null): JsonResponse
    {
        return $this->errorResponse(
            $message ?? 'غير مصرح. يرجى تسجيل الدخول.',
            401,
        );
    }

    protected function forbiddenResponse(?string $message = null, ?string $errorCode = null): JsonResponse
    {
        return $this->errorResponse(
            $message ?? 'غير مصرح لك بالوصول.',
            403,
            null,
            $errorCode,
        );
    }
}
