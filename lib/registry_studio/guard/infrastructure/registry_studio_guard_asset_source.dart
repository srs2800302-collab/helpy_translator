import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/domain/entities/registry_entity.dart';
import '../../core/domain/evidence/source_evidence.dart';
import '../../core/domain/value_objects/registry_entity_id.dart';
import '../../core/domain/value_objects/registry_path.dart';
import '../../core/domain/value_objects/registry_relation.dart';
import '../../core/domain/value_objects/registry_relation_meaning.dart';
import '../domain/registry_studio_guard_record_payload.dart';

final class RegistryStudioGuardAssetSource {
  const RegistryStudioGuardAssetSource({
    required this.assetBundle,
    this.assetPath = defaultAssetPath,
  });

  static const String defaultAssetPath =
      'docs/architecture/registry_studio/'
      'Registry_Studio_Clean_Rebuild_Guard_v1.md';

  static const String _supportedDeclarationVersion = 'v1';

  final AssetBundle assetBundle;
  final String assetPath;

  Future<({RegistryEntity entity, List<RegistryRelation> relations})>
  load() async {
    final String source = await assetBundle.loadString(assetPath);

    return decode(source);
  }

  ({RegistryEntity entity, List<RegistryRelation> relations}) decode(
    String source,
  ) {
    final RegExp declarationPattern = RegExp(
      r'<!--\s*registry-studio-guard-record:([^\s]+)',
    );

    final List<RegExpMatch> declarations = declarationPattern
        .allMatches(source)
        .toList(growable: false);

    if (declarations.isEmpty) {
      throw const FormatException(
        'Registry Studio Guard declaration was not found.',
      );
    }

    if (declarations.length != 1) {
      throw const FormatException(
        'Registry Studio Guard must contain exactly one declaration.',
      );
    }

    final RegExpMatch declaration = declarations.single;
    final String version = declaration.group(1)!;

    if (version != _supportedDeclarationVersion) {
      throw FormatException(
        'Unsupported Registry Studio Guard declaration version: $version.',
      );
    }

    final int jsonStart = source.indexOf('\n', declaration.end);
    final int commentEnd = source.indexOf('-->', declaration.end);

    if (jsonStart == -1 || commentEnd == -1 || jsonStart >= commentEnd) {
      throw const FormatException(
        'Registry Studio Guard declaration is incomplete.',
      );
    }

    final Object? decoded = jsonDecode(
      source.substring(jsonStart + 1, commentEnd).trim(),
    );

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Registry Studio Guard declaration must be a JSON object.',
      );
    }

    final RegistryEntityId entityId = RegistryEntityId(
      _requiredString(decoded, 'entityId'),
    );

    final RegistryStudioGuardRecordPayload payload =
        RegistryStudioGuardRecordPayload(
          recordType: _recordType(_requiredString(decoded, 'recordType')),
          heading: _requiredString(decoded, 'heading'),
          summary: _requiredString(decoded, 'summary'),
        );

    final SourceEvidence sourceEvidence = SourceEvidence(
      sourceDocumentPath: assetPath,
      sourceSnapshotFingerprint: _fingerprint(source),
      headingPath: <String>[payload.heading],
      startLine: _lineNumberAt(source, declaration.start),
      endLine: _lineNumberAt(source, commentEnd + 3),
    );

    final List<RegistryRelation> relations = _requiredList(
      decoded,
      'relations',
    ).map<RegistryRelation>(_decodeRelation).toList(growable: false);

    return (
      entity: RegistryEntity(
        id: entityId,
        path: RegistryPath(_requiredStringList(decoded, 'path')),
        payload: payload,
        sourceEvidence: <SourceEvidence>[sourceEvidence],
      ),
      relations: List<RegistryRelation>.unmodifiable(relations),
    );
  }
}

RegistryRelation _decodeRelation(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException(
      'Each Registry Studio Guard relation must be a JSON object.',
    );
  }

  return RegistryRelation(
    sourceEntityId: RegistryEntityId(_requiredString(value, 'sourceEntityId')),
    targetEntityId: RegistryEntityId(_requiredString(value, 'targetEntityId')),
    meaning: RegistryRelationMeaning(_requiredString(value, 'meaning')),
  );
}

RegistryStudioGuardRecordType _recordType(String value) {
  for (final RegistryStudioGuardRecordType type
      in RegistryStudioGuardRecordType.values) {
    if (type.name == value) {
      return type;
    }
  }

  throw FormatException('Unknown Registry Studio Guard record type: $value.');
}

String _requiredString(Map<String, dynamic> source, String key) {
  final Object? value = source[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException(
      'Registry Studio Guard field "$key" must be a non-empty string.',
    );
  }

  return value;
}

List<String> _requiredStringList(Map<String, dynamic> source, String key) {
  final Object? value = source[key];

  if (value is! List<dynamic> ||
      value.isEmpty ||
      value.any((Object? item) => item is! String)) {
    throw FormatException(
      'Registry Studio Guard field "$key" must be a non-empty string list.',
    );
  }

  return value.cast<String>();
}

List<dynamic> _requiredList(Map<String, dynamic> source, String key) {
  final Object? value = source[key];

  if (value is! List<dynamic>) {
    throw FormatException('Registry Studio Guard field "$key" must be a list.');
  }

  return value;
}

int _lineNumberAt(String source, int offset) {
  return '\n'.allMatches(source.substring(0, offset)).length + 1;
}

String _fingerprint(String source) {
  const int offsetBasis = 0xcbf29ce484222325;
  const int prime = 0x100000001b3;
  const int mask = 0xffffffffffffffff;

  int hash = offsetBasis;

  for (final int byte in utf8.encode(source)) {
    hash ^= byte;
    hash = (hash * prime) & mask;
  }

  return 'fnv1a64:${hash.toRadixString(16).padLeft(16, '0')}';
}
