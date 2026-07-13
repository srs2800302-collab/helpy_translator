import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../../../core/domain/value_objects/registry_path.dart';

typedef ServiceIntakeIdentityManifestEntry = ({
  RegistryEntityId entityId,
  RegistryPath path,
  int ownerHeadingLevel,
  String ownerHeading,
  int headingLevel,
  String heading,
});

final class ServiceIntakeIdentityManifestSource {
  const ServiceIntakeIdentityManifestSource({
    required this.assetBundle,
    this.assetPath = defaultAssetPath,
  });

  static const String defaultAssetPath =
      'assets/registry_studio/helpy/'
      'service_intake_identity_manifest_v1.json';

  static const String _supportedVersion = 'v1';

  final AssetBundle assetBundle;
  final String assetPath;

  Future<List<ServiceIntakeIdentityManifestEntry>> load() async {
    final String source = await assetBundle.loadString(assetPath);

    return decode(source);
  }

  List<ServiceIntakeIdentityManifestEntry> decode(String source) {
    final Object? decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Service intake identity manifest must be a JSON object.',
      );
    }

    _ensureExactKeys(decoded, const <String>{
      'version',
      'entries',
    }, 'Service intake identity manifest');

    final String version = _requiredString(decoded, 'version');

    if (version != _supportedVersion) {
      throw FormatException(
        'Unsupported service intake identity manifest version: $version.',
      );
    }

    final List<dynamic> encodedEntries = _requiredList(decoded, 'entries');

    if (encodedEntries.isEmpty) {
      throw const FormatException(
        'Service intake identity manifest must contain at least one entry.',
      );
    }

    final List<ServiceIntakeIdentityManifestEntry> entries =
        <ServiceIntakeIdentityManifestEntry>[];

    final Set<RegistryEntityId> entityIds = <RegistryEntityId>{};
    final Set<RegistryPath> paths = <RegistryPath>{};
    final Set<(int, String, int, String)> sourceLocators =
        <(int, String, int, String)>{};

    for (final Object? encodedEntry in encodedEntries) {
      final ServiceIntakeIdentityManifestEntry entry = _decodeEntry(
        encodedEntry,
      );

      if (!entityIds.add(entry.entityId)) {
        throw FormatException(
          'Duplicate service intake entity identity: '
          '${entry.entityId.value}.',
        );
      }

      if (!paths.add(entry.path)) {
        throw FormatException(
          'Duplicate service intake registry path: '
          '${entry.path.segments.join("/")}.',
        );
      }

      final (int, String, int, String) locator = (
        entry.ownerHeadingLevel,
        entry.ownerHeading,
        entry.headingLevel,
        entry.heading,
      );

      if (!sourceLocators.add(locator)) {
        throw FormatException(
          'Duplicate service intake source locator: '
          '${entry.ownerHeading} → ${entry.heading}.',
        );
      }

      entries.add(entry);
    }

    return List<ServiceIntakeIdentityManifestEntry>.unmodifiable(entries);
  }
}

ServiceIntakeIdentityManifestEntry _decodeEntry(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Each service intake identity manifest entry',
  );

  _ensureExactKeys(source, const <String>{
    'entityId',
    'path',
    'sourceLocator',
  }, 'Service intake identity manifest entry');

  final RegistryEntityId entityId = RegistryEntityId(
    _requiredString(source, 'entityId'),
  );

  final RegistryPath path = RegistryPath(_requiredStringList(source, 'path'));

  final List<String> identitySegments = entityId.value.split('.');

  if (identitySegments.length != 4 ||
      identitySegments[0] != 'helpy' ||
      identitySegments[1] != 'service_intake') {
    throw FormatException(
      'Service intake RegistryEntityId "${entityId.value}" must use '
      'the "helpy.service_intake.<group>.<key>" namespace.',
    );
  }

  if (!_sameSegments(identitySegments, path.segments)) {
    throw FormatException(
      'Service intake RegistryEntityId "${entityId.value}" must match '
      'RegistryPath "${path.segments.join("/")}".',
    );
  }

  final Map<String, dynamic> locator = _requiredObject(
    source['sourceLocator'],
    'Service intake source locator',
  );

  _ensureExactKeys(locator, const <String>{
    'ownerHeadingLevel',
    'ownerHeading',
    'headingLevel',
    'heading',
  }, 'Service intake source locator');

  return (
    entityId: entityId,
    path: path,
    ownerHeadingLevel: _requiredHeadingLevel(locator, 'ownerHeadingLevel', 2),
    ownerHeading: _requiredString(locator, 'ownerHeading'),
    headingLevel: _requiredHeadingLevel(locator, 'headingLevel', 3),
    heading: _requiredString(locator, 'heading'),
  );
}

Map<String, dynamic> _requiredObject(Object? value, String context) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$context must be a JSON object.');
  }

  return value;
}

String _requiredString(Map<String, dynamic> source, String key) {
  final Object? value = source[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException(
      'Service intake identity manifest field "$key" '
      'must be a non-empty string.',
    );
  }

  return value.trim();
}

List<String> _requiredStringList(Map<String, dynamic> source, String key) {
  final Object? value = source[key];

  if (value is! List<dynamic> || value.isEmpty) {
    throw FormatException(
      'Service intake identity manifest field "$key" '
      'must be a non-empty string list.',
    );
  }

  final List<String> normalized = <String>[];

  for (final Object? item in value) {
    if (item is! String || item.trim().isEmpty) {
      throw FormatException(
        'Service intake identity manifest field "$key" '
        'must contain only non-empty strings.',
      );
    }

    normalized.add(item.trim());
  }

  return List<String>.unmodifiable(normalized);
}

List<dynamic> _requiredList(Map<String, dynamic> source, String key) {
  final Object? value = source[key];

  if (value is! List<dynamic>) {
    throw FormatException(
      'Service intake identity manifest field "$key" must be a list.',
    );
  }

  return value;
}

int _requiredHeadingLevel(
  Map<String, dynamic> source,
  String key,
  int expected,
) {
  final Object? value = source[key];

  if (value != expected) {
    throw FormatException(
      'Service intake source locator field "$key" '
      'must be Markdown heading level $expected.',
    );
  }

  return expected;
}

void _ensureExactKeys(
  Map<String, dynamic> source,
  Set<String> expected,
  String context,
) {
  final Set<String> actual = source.keys.toSet();

  if (actual.length == expected.length && actual.containsAll(expected)) {
    return;
  }

  final List<String> missing = expected.difference(actual).toList()..sort();
  final List<String> unknown = actual.difference(expected).toList()..sort();

  throw FormatException(
    '$context has invalid fields. '
    'Missing: ${missing.join(", ")}. '
    'Unknown: ${unknown.join(", ")}.',
  );
}

bool _sameSegments(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }

  for (int index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}
