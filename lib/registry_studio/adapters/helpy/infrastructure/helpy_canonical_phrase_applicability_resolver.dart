import '../../../canonical/application/contracts/canonical_phrase_applicability_resolver.dart';
import '../../../canonical/domain/entities/canonical_business_text_candidate.dart';
import '../../../canonical/domain/entities/canonical_confirmed_application_evidence.dart';
import '../../../canonical/domain/entities/canonical_phrase_entry.dart';

final class HelpyCanonicalPhraseApplicabilityResolver
    implements CanonicalPhraseApplicabilityResolver {
  const HelpyCanonicalPhraseApplicabilityResolver();

  static const String confirmationEvidenceId =
      'helpy.canonical.structured-applicability.v1';

  static final RegExp _scenario = RegExp(
    r'^(?:Используется только для сценария|Used only for scenario)'
    r'\s+[«"](.+?)[»"]\.?$',
    caseSensitive: false,
  );

  @override
  CanonicalPhraseApplicabilityResolution resolve({
    required CanonicalBusinessTextCandidate candidate,
    required CanonicalPhraseEntry entry,
    required String registrySourceRevision,
  }) {
    bool unresolved = false;

    for (final String raw in entry.applicability) {
      final String rule = raw.trim().replaceAll(RegExp(r'\s+'), ' ');

      if (rule.startsWith('ContentBlockIdentity: ')) {
        if (candidate.contentBlockIdentity !=
            rule.substring('ContentBlockIdentity: '.length).trim()) {
          return const CanonicalPhraseApplicabilityResolution.notApplicable();
        }
        continue;
      }

      if (rule.startsWith('ScenarioIdentity: ')) {
        if (candidate.scenarioIdentity !=
            rule.substring('ScenarioIdentity: '.length).trim()) {
          return const CanonicalPhraseApplicabilityResolution.notApplicable();
        }
        continue;
      }

      if (rule.startsWith('RegistryPath: ')) {
        final String expected = _path(rule.substring('RegistryPath: '.length));
        final String actual = _path(candidate.path.segments.join(' -> '));
        if (expected != actual) {
          return const CanonicalPhraseApplicabilityResolution.notApplicable();
        }
        continue;
      }

      final RegExpMatch? match = _scenario.firstMatch(rule);
      if (match != null) {
        final String? label = candidate.scenarioLabel;
        if (label == null || _label(label) != _label(match.group(1)!)) {
          return const CanonicalPhraseApplicabilityResolution.notApplicable();
        }
        continue;
      }

      unresolved = true;
    }

    if (unresolved) {
      return const CanonicalPhraseApplicabilityResolution.unresolved();
    }

    return CanonicalPhraseApplicabilityResolution.applicable(
      CanonicalConfirmedApplicationEvidence(
        identity:
            '${entry.identity}::confirmed::${Uri.encodeComponent(candidate.identity)}::${Uri.encodeComponent(registrySourceRevision)}',
        candidateIdentity: candidate.identity,
        canonicalEntryIdentity: entry.identity,
        registrySourceRevision: registrySourceRevision,
        confirmationEvidenceId: confirmationEvidenceId,
        sourceEvidence: candidate.sourceEvidence,
      ),
    );
  }

  static String _label(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'\s+'), ' ');

  static String _path(String value) => value
      .trim()
      .replaceAll(RegExp(r'\s*(?:->|→)\s*'), ' -> ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
