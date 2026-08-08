<?php

namespace App\Services\LessonFiles;

use App\Models\LessonFile;
use App\Services\Bunny\BunnyFilesStorageClient;

class LessonFileBunnyStorageAuditService
{
    public function __construct(
        protected BunnyFilesStorageClient $storage,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function audit(): array
    {
        $dbPaths = LessonFile::query()
            ->whereNotNull('external_path')
            ->where('external_path', '!=', '')
            ->pluck('external_path', 'id')
            ->all();

        $dbPathValues = array_values($dbPaths);
        $dbPathCounts = array_count_values(array_map('strval', $dbPathValues));

        $remoteObjects = $this->storage->isConfigured()
            ? $this->collectRemoteObjects('lesson-files')
            : [];

        $remotePaths = array_column($remoteObjects, 'path');
        $remotePathSet = array_fill_keys($remotePaths, true);

        $linked = [];
        $missingRemote = [];
        $duplicateDbPaths = [];

        foreach ($dbPathCounts as $path => $count) {
            if ($count > 1) {
                $duplicateDbPaths[] = [
                    'external_path' => $path,
                    'record_count' => $count,
                ];
            }
        }

        foreach ($dbPaths as $fileId => $path) {
            $normalized = $this->normalizePath((string) $path);
            if (isset($remotePathSet[$normalized])) {
                $linked[] = [
                    'file_id' => $fileId,
                    'external_path' => $normalized,
                ];
            } else {
                $missingRemote[] = [
                    'file_id' => $fileId,
                    'external_path' => $normalized,
                ];
            }
        }

        $linkedPathSet = array_fill_keys(array_column($linked, 'external_path'), true);
        $orphans = [];

        foreach ($remoteObjects as $object) {
            $path = $object['path'];
            if (! isset($linkedPathSet[$path])) {
                $orphans[] = $object;
            }
        }

        $remoteDuplicates = $this->detectRemoteDuplicates($remoteObjects);

        return [
            'summary' => [
                'remote_objects' => count($remoteObjects),
                'linked_objects' => count($linked),
                'orphan_objects' => count($orphans),
                'missing_remote_objects' => count($missingRemote),
                'duplicate_db_paths' => count($duplicateDbPaths),
                'duplicate_remote_groups' => count($remoteDuplicates),
                'bunny_configured' => $this->storage->isConfigured(),
            ],
            'linked' => $linked,
            'orphans' => $orphans,
            'missing_remote' => $missingRemote,
            'duplicate_db_paths' => $duplicateDbPaths,
            'duplicate_remote_groups' => $remoteDuplicates,
        ];
    }

    public function isConfirmedOrphan(string $path): bool
    {
        $normalized = $this->normalizePath($path);
        $report = $this->audit();

        foreach ($report['orphans'] as $orphan) {
            if ($orphan['path'] === $normalized) {
                return true;
            }
        }

        return false;
    }

    /**
     * @return list<array{path: string, object_name: string, size_bytes: int}>
     */
    protected function collectRemoteObjects(string $prefix): array
    {
        $objects = [];
        $this->walkRemoteDirectory($prefix, $objects);

        return $objects;
    }

    /**
     * @param  list<array{path: string, object_name: string, size_bytes: int}>  $objects
     */
    protected function walkRemoteDirectory(string $path, array &$objects): void
    {
        try {
            $items = $this->storage->listDirectory($path);
        } catch (\Throwable) {
            return;
        }

        foreach ($items as $item) {
            if (($item['IsDirectory'] ?? false) === true) {
                $name = (string) ($item['ObjectName'] ?? '');
                if ($name === '') {
                    continue;
                }
                $child = trim($path.'/'.$name, '/');
                $this->walkRemoteDirectory($child, $objects);

                continue;
            }

            $objectName = (string) ($item['ObjectName'] ?? '');
            if ($objectName === '') {
                continue;
            }

            $objects[] = [
                'path' => $this->normalizePath(trim($path.'/'.$objectName, '/')),
                'object_name' => $objectName,
                'size_bytes' => (int) ($item['Length'] ?? 0),
            ];
        }
    }

    /**
     * @param  list<array{path: string, object_name: string, size_bytes: int}>  $remoteObjects
     * @return list<array{object_name: string, paths: list<string>}>
     */
    protected function detectRemoteDuplicates(array $remoteObjects): array
    {
        $byName = [];

        foreach ($remoteObjects as $object) {
            $dir = dirname($object['path']);
            $key = $dir.'/'.$object['object_name'];
            $byName[$key][] = $object['path'];
        }

        $duplicates = [];
        foreach ($byName as $key => $paths) {
            if (count($paths) > 1) {
                $duplicates[] = [
                    'object_name' => basename((string) $key),
                    'paths' => $paths,
                ];
            }
        }

        return $duplicates;
    }

    protected function normalizePath(string $path): string
    {
        return trim(str_replace('\\', '/', $path), '/');
    }
}
