import 'dart:convert';
import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';

import '../../core/domain/evidence/source_evidence.dart';
import '../../core/domain/value_objects/registry_entity_id.dart';
import '../../core/domain/value_objects/registry_path.dart';
import '../../registry/application/contracts/registry_snapshot_cache.dart';
import '../../registry/domain/entities/registry_node.dart';
import '../../registry/domain/entities/registry_snapshot.dart';
import '../../registry/domain/value_objects/registry_node_id.dart';

final class JsonFileRegistrySnapshotCache implements RegistrySnapshotCache {
  const JsonFileRegistrySnapshotCache({this.applicationSupportDirectory});

  static const String directoryName = 'registry_studio';
  static const String snapshotsDirectoryName = 'registry_snapshots_v1';
  static const String _version = 'v1';
  static const int _maximumCacheBytes = 32 * 1024 * 1024;
  static const int _maximumNodes = 100000;
  static const int _maximumDepth = 128;

  final Directory? applicationSupportDirectory;

  @override
  Future<RegistrySnapshot?> loadSnapshot(String sourceRevision) async {
    final String normalizedRevision = sourceRevision.trim();

    if (normalizedRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'Registry snapshot revision must not be empty.',
      );
    }

    final File file = await _file(normalizedRevision);

    if (!await file.exists()) {
      return null;
    }

    final int length = await file.length();

    if (length <= 0 || length > _maximumCacheBytes) {
      throw const FormatException('Registry snapshot cache size is invalid.');
    }

    final Object? decoded = jsonDecode(await file.readAsString());
    final Map<String, Object?> state = _map(decoded, 'Registry snapshot cache');
    const Set<String> expectedKeys = <String>{
      'version',
      'projectId',
      'projectAdapterId',
      'sourceDocumentPath',
      'sourceRevision',
      'sourceSnapshotFingerprint',
      'sourceContent',
      'roots',
    };

    _requireExactKeys(state, expectedKeys, 'Registry snapshot cache');

    if (state['version'] != _version) {
      throw const FormatException(
        'Registry snapshot cache version is unsupported.',
      );
    }

    final String cachedRevision = _string(
      state['sourceRevision'],
      'sourceRevision',
    );

    if (cachedRevision != normalizedRevision) {
      throw const FormatException(
        'Registry snapshot cache revision does not match its lookup key.',
      );
    }

    final List<Object?> rootValues = _list(state['roots'], 'roots');
    final _RegistrySnapshotDecodeBudget budget =
        _RegistrySnapshotDecodeBudget();

    final List<RegistryNode> roots = rootValues
        .map((Object? value) => _decodeNode(value, budget: budget, depth: 0))
        .toList(growable: false);

    try {
      return RegistrySnapshot(
        projectId: _string(state['projectId'], 'projectId'),
        projectAdapterId: _string(
          state['projectAdapterId'],
          'projectAdapterId',
        ),
        sourceDocumentPath: _string(
          state['sourceDocumentPath'],
          'sourceDocumentPath',
        ),
        sourceRevision: cachedRevision,
        sourceSnapshotFingerprint: _string(
          state['sourceSnapshotFingerprint'],
          'sourceSnapshotFingerprint',
        ),
        sourceContent: _string(state['sourceContent'], 'sourceContent'),
        roots: roots,
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        'Registry snapshot cache values are invalid.',
        error,
      );
    }
  }

  @override
  Future<void> saveSnapshot(RegistrySnapshot snapshot) async {
    if (snapshot.entities.isNotEmpty || snapshot.relations.isNotEmpty) {
      throw UnsupportedError(
        'The structural Registry snapshot cache cannot persist semantic '
        'entities or relations.',
      );
    }

    final File file = await _file(snapshot.sourceRevision);
    await file.parent.create(recursive: true);

    final Map<String, Object?> state = <String, Object?>{
      'version': _version,
      'projectId': snapshot.projectId,
      'projectAdapterId': snapshot.projectAdapterId,
      'sourceDocumentPath': snapshot.sourceDocumentPath,
      'sourceRevision': snapshot.sourceRevision,
      'sourceSnapshotFingerprint': snapshot.sourceSnapshotFingerprint,
      'sourceContent': snapshot.sourceContent,
      'roots': snapshot.roots
          .map<Map<String, Object?>>(_encodeNode)
          .toList(growable: false),
    };

    final String encoded = '${jsonEncode(state)}\n';

    if (utf8.encode(encoded).length > _maximumCacheBytes) {
      throw StateError('Registry snapshot cache exceeds the size limit.');
    }

    final File temporary = File('${file.path}.tmp');

    if (await temporary.exists()) {
      await temporary.delete();
    }

    try {
      await temporary.writeAsString(encoded, flush: true);
      await temporary.rename(file.path);
    } catch (_) {
      if (await temporary.exists()) {
        await temporary.delete();
      }

      rethrow;
    }
  }

  Future<File> _file(String sourceRevision) async {
    final Directory supportDirectory;

    if (applicationSupportDirectory != null) {
      supportDirectory = applicationSupportDirectory!;
    } else {
      final String? path = await PathProviderAndroid()
          .getApplicationSupportPath();

      if (path == null || path.trim().isEmpty) {
        throw StateError(
          'Android application support directory is unavailable.',
        );
      }

      supportDirectory = Directory(path);
    }

    final String fileName = base64Url
        .encode(utf8.encode(sourceRevision.trim()))
        .replaceAll('=', '');

    return File(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName'
      '${Platform.pathSeparator}'
      '$snapshotsDirectoryName'
      '${Platform.pathSeparator}'
      '$fileName.json',
    );
  }

  static Map<String, Object?> _encodeNode(RegistryNode node) {
    return <String, Object?>{
      'id': node.id.value,
      'kindId': node.kindId,
      'path': node.path.segments,
      'sourceEvidence': node.sourceEvidence
          .map<Map<String, Object?>>(
            (SourceEvidence evidence) => <String, Object?>{
              'sourceDocumentPath': evidence.sourceDocumentPath,
              'sourceSnapshotFingerprint': evidence.sourceSnapshotFingerprint,
              'headingPath': evidence.headingPath,
              'startLine': evidence.startLine,
              'endLine': evidence.endLine,
            },
          )
          .toList(growable: false),
      'content': node.content,
      'businessScopeOwnerId': node.businessScopeOwnerId?.value,
      'children': node.children
          .map<Map<String, Object?>>(_encodeNode)
          .toList(growable: false),
    };
  }

  static RegistryNode _decodeNode(
    Object? value, {
    required _RegistrySnapshotDecodeBudget budget,
    required int depth,
  }) {
    if (depth > _maximumDepth) {
      throw const FormatException(
        'Registry snapshot cache nesting is too deep.',
      );
    }

    budget.nodeCount += 1;

    if (budget.nodeCount > _maximumNodes) {
      throw const FormatException(
        'Registry snapshot cache contains too many nodes.',
      );
    }

    final Map<String, Object?> node = _map(value, 'Registry node');
    const Set<String> expectedKeys = <String>{
      'id',
      'kindId',
      'path',
      'sourceEvidence',
      'content',
      'businessScopeOwnerId',
      'children',
    };

    _requireExactKeys(node, expectedKeys, 'Registry node');

    final List<String> path = _stringList(node['path'], 'Registry node path');
    final List<Object?> evidenceValues = _list(
      node['sourceEvidence'],
      'Registry node source evidence',
    );
    final List<Object?> childValues = _list(
      node['children'],
      'Registry node children',
    );
    final Object? ownerId = node['businessScopeOwnerId'];

    if (ownerId != null && ownerId is! String) {
      throw const FormatException(
        'Registry node business scope owner must be a string or null.',
      );
    }

    final List<SourceEvidence> sourceEvidence = evidenceValues
        .map((Object? evidence) => _decodeEvidence(evidence))
        .toList(growable: false);
    final List<RegistryNode> children = childValues
        .map(
          (Object? child) =>
              _decodeNode(child, budget: budget, depth: depth + 1),
        )
        .toList(growable: false);

    try {
      return RegistryNode(
        id: RegistryNodeId(_string(node['id'], 'Registry node id')),
        kindId: _string(node['kindId'], 'Registry node kindId'),
        path: RegistryPath(path),
        sourceEvidence: sourceEvidence,
        content: _requiredStringValue(node['content'], 'Registry node content'),
        businessScopeOwnerId: ownerId == null
            ? null
            : RegistryEntityId(ownerId as String),
        children: children,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Registry node values are invalid.', error);
    }
  }

  static SourceEvidence _decodeEvidence(Object? value) {
    final Map<String, Object?> evidence = _map(value, 'Source evidence');
    const Set<String> expectedKeys = <String>{
      'sourceDocumentPath',
      'sourceSnapshotFingerprint',
      'headingPath',
      'startLine',
      'endLine',
    };

    _requireExactKeys(evidence, expectedKeys, 'Source evidence');

    final Object? startLine = evidence['startLine'];
    final Object? endLine = evidence['endLine'];

    if (startLine is! int || endLine is! int) {
      throw const FormatException(
        'Source evidence line numbers must be integers.',
      );
    }

    try {
      return SourceEvidence(
        sourceDocumentPath: _string(
          evidence['sourceDocumentPath'],
          'Source evidence document path',
        ),
        sourceSnapshotFingerprint: _string(
          evidence['sourceSnapshotFingerprint'],
          'Source evidence fingerprint',
        ),
        headingPath: _stringList(
          evidence['headingPath'],
          'Source evidence heading path',
        ),
        startLine: startLine,
        endLine: endLine,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Source evidence values are invalid.', error);
    }
  }

  static Map<String, Object?> _map(Object? value, String name) {
    if (value is! Map<Object?, Object?> ||
        value.keys.any((Object? key) => key is! String)) {
      throw FormatException('$name must be a JSON object.');
    }

    return value.cast<String, Object?>();
  }

  static List<Object?> _list(Object? value, String name) {
    if (value is! List<Object?>) {
      throw FormatException('$name must be a JSON array.');
    }

    return value;
  }

  static List<String> _stringList(Object? value, String name) {
    final List<Object?> values = _list(value, name);

    if (values.any((Object? item) => item is! String)) {
      throw FormatException('$name must contain only strings.');
    }

    return values.cast<String>();
  }

  static String _string(Object? value, String name) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$name must be a nonempty string.');
    }

    return value;
  }

  static String _requiredStringValue(Object? value, String name) {
    if (value is! String) {
      throw FormatException('$name must be a string.');
    }

    return value;
  }

  static void _requireExactKeys(
    Map<String, Object?> value,
    Set<String> expected,
    String name,
  ) {
    final Set<String> actual = value.keys.toSet();

    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw FormatException('$name schema is invalid.');
    }
  }
}

final class _RegistrySnapshotDecodeBudget {
  int nodeCount = 0;
}
