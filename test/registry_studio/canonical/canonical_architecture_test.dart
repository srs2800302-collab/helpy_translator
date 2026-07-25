import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/canonical/helpy_canonical_dictionary_reader.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/canonical_analysis_package.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('frozen canonical adapter architecture', () {
    test('contains exactly six approved production files', () {
      final List<String> actualFiles = <String>[];

      for (final String root in <String>[
        'lib/registry_studio/canonical',
        'lib/registry_studio/adapters/helpy/canonical',
      ]) {
        actualFiles.addAll(
          Directory(root)
              .listSync(recursive: true)
              .whereType<File>()
              .map((File file) => file.path)
              .where((String path) => path.endsWith('.dart')),
        );
      }

      actualFiles.sort();

      expect(actualFiles, <String>[
        'lib/registry_studio/adapters/helpy/canonical/'
            'helpy_canonical_adapter.dart',
        'lib/registry_studio/adapters/helpy/canonical/'
            'helpy_canonical_dictionary_reader.dart',
        'lib/registry_studio/adapters/helpy/canonical/'
            'helpy_canonical_registry_projector.dart',
        'lib/registry_studio/canonical/application/'
            'project_canonical_adapter.dart',
        'lib/registry_studio/canonical/domain/'
            'canonical_analysis_package.dart',
        'lib/registry_studio/canonical/domain/'
            'canonical_dictionary.dart',
      ]);
    });

    test('scenario owns exactly one block of every required role', () {
      final CanonicalBusinessScenario scenario = _scenario('install');

      expect(
        scenario.blockForRole(CanonicalContentRole.questions).role,
        CanonicalContentRole.questions,
      );
      expect(
        scenario.blockForRole(CanonicalContentRole.photoQuestions).role,
        CanonicalContentRole.photoQuestions,
      );
      expect(
        scenario.blockForRole(CanonicalContentRole.clientRules).role,
        CanonicalContentRole.clientRules,
      );
      expect(
        scenario.blockForRole(CanonicalContentRole.masterRules).role,
        CanonicalContentRole.masterRules,
      );

      expect(
        () => CanonicalBusinessScenario(
          identity: 'scenario.invalid.missing',
          label: 'Missing block',
          path: RegistryPath(<String>['Root', 'Entity', 'Missing']),
          sourceNodeId: RegistryNodeId('node.scenario.missing'),
          blocks: <CanonicalBusinessBlock>[
            _block(CanonicalContentRole.questions, 'missing.questions'),
            _block(
              CanonicalContentRole.photoQuestions,
              'missing.photoQuestions',
            ),
            _block(CanonicalContentRole.clientRules, 'missing.clientRules'),
          ],
          sourceEvidence: <SourceEvidence>[
            _registryEvidence(
              RegistryPath(<String>['Root', 'Entity', 'Missing']),
              40,
            ),
          ],
        ),
        throwsArgumentError,
      );

      expect(
        () => CanonicalBusinessScenario(
          identity: 'scenario.invalid.duplicate',
          label: 'Duplicate block',
          path: RegistryPath(<String>['Root', 'Entity', 'Duplicate']),
          sourceNodeId: RegistryNodeId('node.scenario.duplicate'),
          blocks: <CanonicalBusinessBlock>[
            _block(CanonicalContentRole.questions, 'duplicate.questions.1'),
            _block(CanonicalContentRole.questions, 'duplicate.questions.2'),
            _block(
              CanonicalContentRole.photoQuestions,
              'duplicate.photoQuestions',
            ),
            _block(CanonicalContentRole.clientRules, 'duplicate.clientRules'),
          ],
          sourceEvidence: <SourceEvidence>[
            _registryEvidence(
              RegistryPath(<String>['Root', 'Entity', 'Duplicate']),
              50,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('shared structural scope may belong to several entities', () {
      final CanonicalBusinessScopeReference sharedScope =
          CanonicalBusinessScopeReference(
            identity: 'scope.electrical',
            kindId: 'mini-scope',
            label: 'Electrical',
            path: RegistryPath(<String>['Root', 'Electrical']),
            sourceNodeId: RegistryNodeId('node.scope.electrical'),
            sourceEvidence: <SourceEvidence>[
              _registryEvidence(
                RegistryPath(<String>['Root', 'Electrical']),
                10,
              ),
            ],
          );

      final CanonicalAnalysisPackage package = CanonicalAnalysisPackage(
        projectId: 'helpy',
        projectAdapterId: 'helpy.canonical.adapter.v1',
        registrySourceDocumentPath: 'registry.md',
        registryRevision: 'registry-revision',
        registrySourceSnapshotFingerprint: 'registry-fingerprint',
        dictionary: _dictionary(),
        businessEntities: <CanonicalBusinessEntity>[
          _entity(
            identity: 'entity.socket',
            label: 'Socket',
            scope: sharedScope,
            scenarioSuffix: 'socket',
            line: 20,
          ),
          _entity(
            identity: 'entity.switch',
            label: 'Switch',
            scope: sharedScope,
            scenarioSuffix: 'switch',
            line: 30,
          ),
        ],
        orderedBusinessBlocks: const <CanonicalOrderedBusinessBlock>[],
        adapterFailures: const <CanonicalAdapterFailure>[],
      );

      expect(package.businessEntities, hasLength(2));
      expect(
        package.businessEntities
            .expand((CanonicalBusinessEntity entity) => entity.scopeLineage)
            .map((CanonicalBusinessScopeReference scope) => scope.identity),
        everyElement('scope.electrical'),
      );
    });

    test('missing dictionary requires a fatal structured failure', () {
      expect(
        () => CanonicalAnalysisPackage(
          projectId: 'helpy',
          projectAdapterId: 'helpy.canonical.adapter.v1',
          registrySourceDocumentPath: 'registry.md',
          registryRevision: 'registry-revision',
          registrySourceSnapshotFingerprint: 'registry-fingerprint',
          dictionary: null,
          businessEntities: const <CanonicalBusinessEntity>[],
          orderedBusinessBlocks: const <CanonicalOrderedBusinessBlock>[],
          adapterFailures: const <CanonicalAdapterFailure>[],
        ),
        throwsArgumentError,
      );

      final CanonicalAnalysisPackage package = CanonicalAnalysisPackage(
        projectId: 'helpy',
        projectAdapterId: 'helpy.canonical.adapter.v1',
        registrySourceDocumentPath: 'registry.md',
        registryRevision: 'registry-revision',
        registrySourceSnapshotFingerprint: 'registry-fingerprint',
        dictionary: null,
        businessEntities: const <CanonicalBusinessEntity>[],
        orderedBusinessBlocks: const <CanonicalOrderedBusinessBlock>[],
        adapterFailures: <CanonicalAdapterFailure>[
          CanonicalAdapterFailure(
            identity: 'failure.dictionary',
            source: CanonicalAdapterFailureSource.dictionary,
            severity: CanonicalAdapterFailureSeverity.fatal,
            code: 'dictionary_unavailable',
            explanation: 'Canonical Dictionary недоступен.',
            relatedIdentity: null,
            path: null,
            sourceEvidence: const <SourceEvidence>[],
          ),
        ],
      );

      expect(package.hasFatalFailure, isTrue);
    });

    test('applicability preserves typed structural dimensions', () {
      final RegistryPath prefix = RegistryPath(<String>['Root', 'Electrical']);

      final CanonicalApplicability applicability = CanonicalApplicability(
        registryPathPrefixes: <RegistryPath>[prefix],
        businessScopeIdentities: const <String>['scope.electrical'],
        entityIdentities: const <String>['entity.socket'],
        scenarioIdentities: const <String>['scenario.install'],
        contentBlockIdentities: const <String>['block.install.questions'],
        contentBlockRoles: const <CanonicalContentRole>[
          CanonicalContentRole.questions,
        ],
      );

      expect(applicability.isUniversal, isFalse);
      expect(applicability.registryPathPrefixes, <RegistryPath>[prefix]);
      expect(applicability.contentBlockRoles, const <CanonicalContentRole>[
        CanonicalContentRole.questions,
      ]);
    });

    test('dictionary reader uses stable markers and metadata', () {
      const String source = '''
# Registry Studio Contract

<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->

Dictionary ID: `REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1`
Dictionary version: `1`
Status: **APPROVED / STORED**

<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->
''';

      final result = const HelpyCanonicalDictionaryReader().read(
        sourceContent: source,
        sourceDocumentPath: 'contract.md',
        sourceRevision: 'contract-revision',
        sourceSnapshotFingerprint: 'contract-fingerprint',
      );

      expect(result.failures, isEmpty);
      expect(result.dictionary, isNotNull);
      expect(
        result.dictionary!.dictionaryId,
        HelpyCanonicalDictionaryReader.expectedDictionaryId,
      );
      expect(
        result.dictionary!.version,
        HelpyCanonicalDictionaryReader.expectedVersion,
      );
    });

    test('dictionary reader rejects duplicate stable markers', () {
      const String source = '''
# Registry Studio Contract

<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->
<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->
<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->
''';

      final result = const HelpyCanonicalDictionaryReader().read(
        sourceContent: source,
        sourceDocumentPath: 'contract.md',
        sourceRevision: 'contract-revision',
        sourceSnapshotFingerprint: 'contract-fingerprint',
      );

      expect(result.dictionary, isNull);
      expect(result.failures, hasLength(1));
      expect(result.failures.single.code, 'dictionary_marker_count_invalid');
      expect(
        result.failures.single.severity,
        CanonicalAdapterFailureSeverity.fatal,
      );
    });
  });
}

CanonicalDictionary _dictionary() {
  return CanonicalDictionary(
    dictionaryId: HelpyCanonicalDictionaryReader.expectedDictionaryId,
    version: HelpyCanonicalDictionaryReader.expectedVersion,
    status: HelpyCanonicalDictionaryReader.expectedStatus,
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'contract-revision',
    sourceSnapshotFingerprint: 'contract-fingerprint',
    beginMarkerLine: 3,
    endMarkerLine: 9,
    phrases: const <CanonicalPhraseEntry>[],
    approvedEquivalents: const <CanonicalApprovedEquivalent>[],
    orderedBlocks: const <CanonicalOrderedBlock>[],
  );
}

CanonicalBusinessEntity _entity({
  required String identity,
  required String label,
  required CanonicalBusinessScopeReference scope,
  required String scenarioSuffix,
  required int line,
}) {
  final RegistryPath path = RegistryPath(<String>['Root', 'Electrical', label]);

  return CanonicalBusinessEntity(
    identity: identity,
    label: label,
    path: path,
    sourceNodeId: RegistryNodeId('node.$identity'),
    businessScopeOwnerId: null,
    scopeLineage: <CanonicalBusinessScopeReference>[scope],
    scenarios: <CanonicalBusinessScenario>[_scenario(scenarioSuffix)],
    sourceEvidence: <SourceEvidence>[_registryEvidence(path, line)],
  );
}

CanonicalBusinessScenario _scenario(String suffix) {
  final RegistryPath path = RegistryPath(<String>[
    'Root',
    'Entity',
    'Scenario $suffix',
  ]);

  return CanonicalBusinessScenario(
    identity: 'scenario.$suffix',
    label: 'Scenario $suffix',
    path: path,
    sourceNodeId: RegistryNodeId('node.scenario.$suffix'),
    blocks: <CanonicalBusinessBlock>[
      _block(CanonicalContentRole.questions, '$suffix.questions'),
      _block(CanonicalContentRole.photoQuestions, '$suffix.photoQuestions'),
      _block(CanonicalContentRole.clientRules, '$suffix.clientRules'),
      _block(CanonicalContentRole.masterRules, '$suffix.masterRules'),
    ],
    sourceEvidence: <SourceEvidence>[_registryEvidence(path, 100)],
  );
}

CanonicalBusinessBlock _block(CanonicalContentRole role, String suffix) {
  final RegistryPath path = RegistryPath(<String>[
    'Root',
    'Entity',
    'Scenario',
    role.name,
    suffix,
  ]);

  return CanonicalBusinessBlock(
    identity: 'block.$suffix',
    role: role,
    label: role.name,
    path: path,
    sourceNodeId: RegistryNodeId('node.block.$suffix'),
    items: <CanonicalBusinessText>[
      CanonicalBusinessText(
        identity: 'text.$suffix',
        text: 'Business text $suffix',
        sourceOrder: 1,
        path: path,
        sourceNodeId: RegistryNodeId('node.text.$suffix'),
        sourceEvidence: <SourceEvidence>[_registryEvidence(path, 200)],
      ),
    ],
    sourceEvidence: <SourceEvidence>[_registryEvidence(path, 200)],
  );
}

SourceEvidence _registryEvidence(RegistryPath path, int line) {
  return SourceEvidence(
    sourceDocumentPath: 'registry.md',
    sourceSnapshotFingerprint: 'registry-fingerprint',
    headingPath: path.segments,
    startLine: line,
    endLine: line,
  );
}
