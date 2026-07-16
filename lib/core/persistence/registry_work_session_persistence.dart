import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation_revision.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_status.dart';

final class RegistryWorkSession {
  const RegistryWorkSession({
    required this.pathTitles,
    required this.pathNodeIds,
    required this.lastPhrase,
    required this.updatedAtIso,
  });

  final List<String> pathTitles;
  final List<String> pathNodeIds;
  final String lastPhrase;
  final String updatedAtIso;

  bool get hasData =>
      pathTitles.isNotEmpty ||
      pathNodeIds.isNotEmpty ||
      lastPhrase.trim().isNotEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'pathTitles': pathTitles,
      'pathNodeIds': pathNodeIds,
      'lastPhrase': lastPhrase,
      'updatedAtIso': updatedAtIso,
    };
  }

  static RegistryWorkSession fromJson(Map<String, dynamic> json) {
    return RegistryWorkSession(
      pathTitles: _stringList(json['pathTitles']),
      pathNodeIds: _stringList(json['pathNodeIds']),
      lastPhrase: _string(json['lastPhrase']),
      updatedAtIso: _string(json['updatedAtIso']),
    );
  }

  static List<String> _stringList(Object? value) {
    return value is List<dynamic>
        ? value.whereType<String>().toList(growable: false)
        : const <String>[];
  }

  static String _string(Object? value) {
    return value is String ? value : '';
  }
}

final class RegistryWorkSessionPersistence {
  const RegistryWorkSessionPersistence();

  static const String _key = 'registry_work_session_v2';
  static const String _engineeringOperationKey =
      'registry_engineering_operation_workspace_v1';

  Future<RegistryWorkSession?> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String? rawV2 = preferences.getString(_key);
    final String? rawV1 = preferences.getString('registry_work_session_v1');
    final String? raw = rawV2 ?? rawV1;

    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final RegistryWorkSession session = RegistryWorkSession.fromJson(decoded);

    return session.hasData ? session : null;
  }

  Future<void> saveSection({
    required List<String> pathTitles,
    required List<String> pathNodeIds,
  }) async {
    await _save(
      RegistryWorkSession(
        pathTitles: pathTitles,
        pathNodeIds: pathNodeIds,
        lastPhrase: '',
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> savePhrase({
    required List<String> pathTitles,
    required List<String> pathNodeIds,
    required String phrase,
  }) async {
    await _save(
      RegistryWorkSession(
        pathTitles: pathTitles,
        pathNodeIds: pathNodeIds,
        lastPhrase: phrase,
        updatedAtIso: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> saveEngineeringOperationWorkspace({
    required RegistryEngineeringOperation operation,
    required Iterable<RegistryEngineeringOperationRevision> revisions,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final Map<String, Object?> payload = <String, Object?>{
      'operation': <String, Object?>{
        'id': operation.id.value,
        'status': operation.status.name,
        'problemStatement': operation.problemStatement,
        'decisionStatement': operation.decisionStatement,
      },
      'revisions': revisions
          .map(
            (RegistryEngineeringOperationRevision revision) =>
                <String, Object?>{
                  'id': revision.id,
                  'operationId': revision.operationId.value,
                  'revisionNumber': revision.revisionNumber,
                  'workingContent': revision.workingContent,
                  'originalValue': revision.originalValue,
                  'proposedValue': revision.proposedValue,
                  'previousRevisionId': revision.previousRevisionId,
                  'primaryEntityId': revision.primaryEntityId.value,
                  'relatedEntityIds': revision.relatedEntityIds
                      .map((RegistryEntityId id) => id.value)
                      .toList(growable: false),
                },
          )
          .toList(growable: false),
    };

    final bool saved = await preferences.setString(
      _engineeringOperationKey,
      jsonEncode(payload),
    );

    if (!saved) {
      throw StateError('Failed to save the engineering operation workspace.');
    }
  }

  Future<RegistryEngineeringOperation?> loadEngineeringOperation() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_engineeringOperationKey);

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return null;
      }

      final Object? operationRaw = Map<String, dynamic>.from(
        decoded,
      )['operation'];

      if (operationRaw is! Map) {
        return null;
      }

      final Map<String, dynamic> operationJson = Map<String, dynamic>.from(
        operationRaw,
      );

      return RegistryEngineeringOperation(
        id: RegistryEngineeringOperationId(operationJson['id'] as String),
        status: RegistryEngineeringOperationStatus.values.byName(
          operationJson['status'] as String,
        ),
        problemStatement: operationJson['problemStatement'] as String,
        decisionStatement: operationJson['decisionStatement'] as String?,
      );
    } on Object {
      return null;
    }
  }

  Future<List<RegistryEngineeringOperationRevision>>
  loadEngineeringOperationRevisions() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_engineeringOperationKey);

    if (raw == null || raw.trim().isEmpty) {
      return const <RegistryEngineeringOperationRevision>[];
    }

    try {
      final Object? decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return const <RegistryEngineeringOperationRevision>[];
      }

      final Object? revisionsRaw = Map<String, dynamic>.from(
        decoded,
      )['revisions'];

      if (revisionsRaw is! List) {
        return const <RegistryEngineeringOperationRevision>[];
      }

      final List<RegistryEngineeringOperationRevision> revisions = revisionsRaw
          .map((Object? item) {
            if (item is! Map) {
              throw const FormatException('Revision JSON must be an object.');
            }

            final Map<String, dynamic> revisionJson = Map<String, dynamic>.from(
              item,
            );
            final Object? relatedRaw = revisionJson['relatedEntityIds'];

            if (relatedRaw is! List) {
              throw const FormatException('relatedEntityIds must be a list.');
            }

            final Object? semanticCandidateDecisionsRaw =
                revisionJson['semanticCandidateDecisions'];
            final Map<String, bool> semanticCandidateDecisions =
                semanticCandidateDecisionsRaw is Map
                ? Map<String, dynamic>.from(semanticCandidateDecisionsRaw).map(
                    (String candidate, dynamic decision) =>
                        MapEntry<String, bool>(candidate, decision as bool),
                  )
                : const <String, bool>{};

            return RegistryEngineeringOperationRevision(
              id: revisionJson['id'] as String,
              operationId: RegistryEngineeringOperationId(
                revisionJson['operationId'] as String,
              ),
              revisionNumber: revisionJson['revisionNumber'] as int,
              workingContent: revisionJson['workingContent'] as String,
              originalValue: revisionJson['originalValue'] as String?,
              proposedValue: revisionJson['proposedValue'] as String?,
              previousRevisionId: revisionJson['previousRevisionId'] as String?,
              primaryEntityId: RegistryEntityId(
                revisionJson['primaryEntityId'] as String,
              ),
              relatedEntityIds: relatedRaw.cast<String>().map(
                RegistryEntityId.new,
              ),
              semanticCandidateDecisions: semanticCandidateDecisions,
            );
          })
          .toList(growable: false);

      return List<RegistryEngineeringOperationRevision>.unmodifiable(revisions);
    } on Object {
      return const <RegistryEngineeringOperationRevision>[];
    }
  }

  Future<void> clearEngineeringOperationWorkspace() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.remove(_engineeringOperationKey);
  }

  Future<void> _save(RegistryWorkSession session) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(session.toJson()));
  }
}
