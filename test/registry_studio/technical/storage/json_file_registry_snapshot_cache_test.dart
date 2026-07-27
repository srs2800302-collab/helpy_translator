import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';
import 'package:helpy_translator/registry_studio/technical/storage/json_file_registry_snapshot_cache.dart';

void main() {
  late Directory directory;
  late JsonFileRegistrySnapshotCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'registry_snapshot_cache_test_',
    );
    cache = JsonFileRegistrySnapshotCache(
      applicationSupportDirectory: directory,
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('returns null when the requested revision is not cached', () async {
    expect(await cache.loadSnapshot('revision-1'), isNull);
  });

  test('persists and restores a complete structural snapshot', () async {
    final RegistrySnapshot snapshot = _snapshot('revision-1');

    await cache.saveSnapshot(snapshot);
    final RegistrySnapshot? restored = await cache.loadSnapshot(
      snapshot.sourceRevision,
    );

    expect(restored, snapshot);
  });

  test('keeps snapshots for different revisions independently', () async {
    final RegistrySnapshot first = _snapshot('revision-1');
    final RegistrySnapshot second = _snapshot('revision-2');

    await cache.saveSnapshot(first);
    await cache.saveSnapshot(second);

    expect(await cache.loadSnapshot('revision-1'), first);
    expect(await cache.loadSnapshot('revision-2'), second);
  });

  test('rejects corrupted cached JSON instead of silently resetting', () async {
    final RegistrySnapshot snapshot = _snapshot('revision-1');
    await cache.saveSnapshot(snapshot);

    final Directory snapshotsDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}'
      '${JsonFileRegistrySnapshotCache.directoryName}'
      '${Platform.pathSeparator}'
      '${JsonFileRegistrySnapshotCache.snapshotsDirectoryName}',
    );
    final List<File> files = snapshotsDirectory
        .listSync()
        .whereType<File>()
        .toList(growable: false);

    expect(files, hasLength(1));
    await files.single.writeAsString('{"version":"v1"}\n');

    await expectLater(
      cache.loadSnapshot(snapshot.sourceRevision),
      throwsFormatException,
    );
  });
}

RegistrySnapshot _snapshot(String revision) {
  const String documentPath = 'docs/registry.md';
  final String fingerprint = 'git-blob:$revision';
  final RegistryPath rootPath = RegistryPath(<String>['Root']);
  final RegistryPath childPath = RegistryPath(<String>['Root', 'Child']);

  SourceEvidence evidence(List<String> headingPath, int line) {
    return SourceEvidence(
      sourceDocumentPath: documentPath,
      sourceSnapshotFingerprint: fingerprint,
      headingPath: headingPath,
      startLine: line,
      endLine: line,
    );
  }

  final RegistryNode child = RegistryNode(
    id: RegistryNodeId('node.child'),
    kindId: 'heading.2',
    path: childPath,
    sourceEvidence: <SourceEvidence>[evidence(childPath.segments, 2)],
    content: 'Child content',
    businessScopeOwnerId: null,
    children: const <RegistryNode>[],
  );

  final RegistryNode root = RegistryNode(
    id: RegistryNodeId('node.root'),
    kindId: 'heading.1',
    path: rootPath,
    sourceEvidence: <SourceEvidence>[evidence(rootPath.segments, 1)],
    content: 'Root content',
    businessScopeOwnerId: null,
    children: <RegistryNode>[child],
  );

  return RegistrySnapshot(
    projectId: 'project',
    projectAdapterId: 'adapter',
    sourceDocumentPath: documentPath,
    sourceRevision: revision,
    sourceSnapshotFingerprint: fingerprint,
    sourceContent: '# Root\n## Child\n',
    roots: <RegistryNode>[root],
  );
}
