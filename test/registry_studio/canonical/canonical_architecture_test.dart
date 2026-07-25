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
          selectorBinding: null,
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
          selectorBinding: null,
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

      final CanonicalScenarioSelectorReference selectorReference =
          _selectorReference();

      final CanonicalBusinessEntity explicitScenarioEntity = _entity(
        identity: 'entity.explicit',
        label: 'Explicit',
        scope: sharedScope,
        scenarioSuffix: 'unused',
        scenarios: <CanonicalBusinessScenario>[
          _scenario(
            'install',
            selectorBinding: _selectorBinding(selectorReference, 'install', 61),
          ),
          _scenario(
            'replace',
            selectorBinding: _selectorBinding(selectorReference, 'replace', 62),
          ),
        ],
        line: 40,
      );

      expect(
        explicitScenarioEntity.scenarios.map(
          (CanonicalBusinessScenario scenario) =>
              scenario.selectorBinding?.optionIdentity,
        ),
        <String?>['install', 'replace'],
      );

      expect(
        () => _entity(
          identity: 'entity.invalid.multiple',
          label: 'Invalid multiple',
          scope: sharedScope,
          scenarioSuffix: 'unused',
          scenarios: <CanonicalBusinessScenario>[
            _scenario('invalid.install'),
            _scenario('invalid.replace'),
          ],
          line: 50,
        ),
        throwsArgumentError,
      );
    });

    test(
      'package validates shared selector identity and selector evidence',
      () {
        final CanonicalBusinessScopeReference sharedScope =
            CanonicalBusinessScopeReference(
              identity: 'scope.selector-validation',
              kindId: 'mini-scope',
              label: 'Selector validation scope',
              path: RegistryPath(<String>['Root', 'Selector validation']),
              sourceNodeId: RegistryNodeId('node.scope.selector-validation'),
              sourceEvidence: <SourceEvidence>[
                _registryEvidence(
                  RegistryPath(<String>['Root', 'Selector validation']),
                  70,
                ),
              ],
            );

        final CanonicalScenarioSelectorReference selectorReference =
            _selectorReference();

        CanonicalBusinessEntity entityWithReference(
          String suffix,
          CanonicalScenarioSelectorReference reference,
          int line,
        ) {
          return _entity(
            identity: 'entity.$suffix',
            label: suffix,
            scope: sharedScope,
            scenarioSuffix: 'unused.$suffix',
            scenarios: <CanonicalBusinessScenario>[
              _scenario(
                '$suffix.install',
                selectorBinding: _selectorBinding(
                  reference,
                  'install',
                  line + 1,
                ),
              ),
              _scenario(
                '$suffix.replace',
                selectorBinding: _selectorBinding(
                  reference,
                  'replace',
                  line + 2,
                ),
              ),
            ],
            line: line,
          );
        }

        CanonicalAnalysisPackage packageFor(
          List<CanonicalBusinessEntity> entities,
        ) {
          return CanonicalAnalysisPackage(
            projectId: 'helpy',
            projectAdapterId: 'helpy.canonical.adapter.v1',
            registrySourceDocumentPath: 'registry.md',
            registryRevision: 'registry-revision',
            registrySourceSnapshotFingerprint: 'registry-fingerprint',
            dictionary: _dictionary(),
            businessEntities: entities,
            orderedBusinessBlocks: const <CanonicalOrderedBusinessBlock>[],
            adapterFailures: const <CanonicalAdapterFailure>[],
          );
        }

        final CanonicalAnalysisPackage validPackage =
            packageFor(<CanonicalBusinessEntity>[
              entityWithReference('selector.first', selectorReference, 80),
              entityWithReference('selector.second', selectorReference, 90),
            ]);

        expect(validPackage.businessEntities, hasLength(2));

        final RegistryPath conflictingPath = RegistryPath(<String>[
          'Root',
          'Electrical',
          'Conflicting Work Type',
        ]);
        final CanonicalScenarioSelectorReference conflictingReference =
            CanonicalScenarioSelectorReference(
              identity: selectorReference.identity,
              kindId: selectorReference.kindId,
              label: selectorReference.label,
              path: conflictingPath,
              sourceNodeId: RegistryNodeId(
                'node.selector.electrical.conflicting-work-type',
              ),
              sourceEvidence: <SourceEvidence>[
                _registryEvidence(conflictingPath, 100),
              ],
            );

        expect(
          () => packageFor(<CanonicalBusinessEntity>[
            entityWithReference('selector.original', selectorReference, 110),
            entityWithReference(
              'selector.conflicting',
              conflictingReference,
              120,
            ),
          ]),
          throwsArgumentError,
        );

        final RegistryPath invalidReferencePath = RegistryPath(<String>[
          'Root',
          'Electrical',
          'Invalid reference',
        ]);
        final CanonicalScenarioSelectorReference invalidReference =
            CanonicalScenarioSelectorReference(
              identity: 'selector.invalid.reference',
              kindId: 'work-type',
              label: 'Invalid reference',
              path: invalidReferencePath,
              sourceNodeId: RegistryNodeId('node.selector.invalid.reference'),
              sourceEvidence: <SourceEvidence>[
                SourceEvidence(
                  sourceDocumentPath: 'other-registry.md',
                  sourceSnapshotFingerprint: 'registry-fingerprint',
                  headingPath: invalidReferencePath.segments,
                  startLine: 130,
                  endLine: 130,
                ),
              ],
            );

        expect(
          () => packageFor(<CanonicalBusinessEntity>[
            entityWithReference(
              'selector.invalid-reference',
              invalidReference,
              131,
            ),
          ]),
          throwsArgumentError,
        );

        final CanonicalScenarioSelectorBinding invalidBinding =
            CanonicalScenarioSelectorBinding(
              selectorReference: selectorReference,
              optionIdentity: 'invalid-binding',
              optionLabel: 'Invalid binding',
              sourceEvidence: <SourceEvidence>[
                SourceEvidence(
                  sourceDocumentPath: 'registry.md',
                  sourceSnapshotFingerprint: 'other-fingerprint',
                  headingPath: selectorReference.path.segments,
                  startLine: 140,
                  endLine: 140,
                ),
              ],
            );

        expect(
          () => packageFor(<CanonicalBusinessEntity>[
            _entity(
              identity: 'entity.selector.invalid-binding',
              label: 'Invalid binding',
              scope: sharedScope,
              scenarioSuffix: 'unused.invalid-binding',
              scenarios: <CanonicalBusinessScenario>[
                _scenario(
                  'selector.invalid-binding',
                  selectorBinding: invalidBinding,
                ),
              ],
              line: 141,
            ),
          ]),
          throwsArgumentError,
        );
      },
    );

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

CanonicalScenarioSelectorReference _selectorReference() {
  final RegistryPath path = RegistryPath(<String>[
    'Root',
    'Electrical',
    'Work Type',
  ]);

  return CanonicalScenarioSelectorReference(
    identity: 'selector.electrical.work-type',
    kindId: 'work-type',
    label: 'Work Type',
    path: path,
    sourceNodeId: RegistryNodeId('node.selector.electrical.work-type'),
    sourceEvidence: <SourceEvidence>[_registryEvidence(path, 60)],
  );
}

CanonicalScenarioSelectorBinding _selectorBinding(
  CanonicalScenarioSelectorReference selectorReference,
  String optionIdentity,
  int line,
) {
  return CanonicalScenarioSelectorBinding(
    selectorReference: selectorReference,
    optionIdentity: optionIdentity,
    optionLabel: optionIdentity,
    sourceEvidence: <SourceEvidence>[
      _registryEvidence(selectorReference.path, line),
    ],
  );
}

CanonicalBusinessEntity _entity({
  required String identity,
  required String label,
  required CanonicalBusinessScopeReference scope,
  required String scenarioSuffix,
  List<CanonicalBusinessScenario>? scenarios,
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
    scenarios:
        scenarios ?? <CanonicalBusinessScenario>[_scenario(scenarioSuffix)],
    sourceEvidence: <SourceEvidence>[_registryEvidence(path, line)],
  );
}

CanonicalBusinessScenario _scenario(
  String suffix, {
  CanonicalScenarioSelectorBinding? selectorBinding,
}) {
  final RegistryPath path = RegistryPath(<String>[
    'Root',
    'Entity',
    'Scenario $suffix',
  ]);

  return CanonicalBusinessScenario(
    identity: 'scenario.$suffix',
    label: 'Scenario $suffix',
    selectorBinding: selectorBinding,
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
