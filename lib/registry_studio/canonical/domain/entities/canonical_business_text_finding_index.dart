import 'package:equatable/equatable.dart';

import 'canonical_business_text_classification.dart';
import 'canonical_business_text_classification_index.dart';
import 'canonical_business_text_classification_status.dart';
import 'canonical_business_text_finding.dart';

final class CanonicalBusinessTextFindingIndex extends Equatable {
  factory CanonicalBusinessTextFindingIndex({
    required CanonicalBusinessTextClassificationIndex classifications,
  }) {
    final List<CanonicalBusinessTextFinding> findings =
        <CanonicalBusinessTextFinding>[];

    final Map<String, CanonicalBusinessTextFinding>
    findingsByCandidateIdentity = <String, CanonicalBusinessTextFinding>{};

    final Map<
      CanonicalBusinessTextClassificationStatus,
      List<CanonicalBusinessTextFinding>
    >
    findingsByStatus =
        <
          CanonicalBusinessTextClassificationStatus,
          List<CanonicalBusinessTextFinding>
        >{
          for (final CanonicalBusinessTextClassificationStatus status
              in CanonicalBusinessTextClassificationStatus.values)
            status: <CanonicalBusinessTextFinding>[],
        };

    final Map<
      CanonicalBusinessTextFindingDisposition,
      List<CanonicalBusinessTextFinding>
    >
    findingsByDisposition =
        <
          CanonicalBusinessTextFindingDisposition,
          List<CanonicalBusinessTextFinding>
        >{
          for (final CanonicalBusinessTextFindingDisposition disposition
              in CanonicalBusinessTextFindingDisposition.values)
            disposition: <CanonicalBusinessTextFinding>[],
        };

    for (final CanonicalBusinessTextClassification classification
        in classifications.classifications) {
      if (classification.status ==
              CanonicalBusinessTextClassificationStatus.exact ||
          classification.status ==
              CanonicalBusinessTextClassificationStatus.equivalent) {
        continue;
      }

      final CanonicalBusinessTextFinding finding = CanonicalBusinessTextFinding(
        classification: classification,
      );

      if (findingsByCandidateIdentity.containsKey(finding.identity)) {
        throw ArgumentError.value(
          finding.identity,
          'classifications',
          'Canonical finding candidate identities must be unique.',
        );
      }

      findings.add(finding);
      findingsByCandidateIdentity[finding.identity] = finding;
      findingsByStatus[finding.status]!.add(finding);
      findingsByDisposition[finding.disposition]!.add(finding);
    }

    return CanonicalBusinessTextFindingIndex._(
      classifications: classifications,
      findings: List<CanonicalBusinessTextFinding>.unmodifiable(findings),
      findingsByCandidateIdentity:
          Map<String, CanonicalBusinessTextFinding>.unmodifiable(
            findingsByCandidateIdentity,
          ),
      findingsByStatus:
          Map<
            CanonicalBusinessTextClassificationStatus,
            List<CanonicalBusinessTextFinding>
          >.unmodifiable(<
            CanonicalBusinessTextClassificationStatus,
            List<CanonicalBusinessTextFinding>
          >{
            for (final MapEntry<
                  CanonicalBusinessTextClassificationStatus,
                  List<CanonicalBusinessTextFinding>
                >
                entry
                in findingsByStatus.entries)
              entry.key: List<CanonicalBusinessTextFinding>.unmodifiable(
                entry.value,
              ),
          }),
      findingsByDisposition:
          Map<
            CanonicalBusinessTextFindingDisposition,
            List<CanonicalBusinessTextFinding>
          >.unmodifiable(<
            CanonicalBusinessTextFindingDisposition,
            List<CanonicalBusinessTextFinding>
          >{
            for (final MapEntry<
                  CanonicalBusinessTextFindingDisposition,
                  List<CanonicalBusinessTextFinding>
                >
                entry
                in findingsByDisposition.entries)
              entry.key: List<CanonicalBusinessTextFinding>.unmodifiable(
                entry.value,
              ),
          }),
    );
  }

  const CanonicalBusinessTextFindingIndex._({
    required this.classifications,
    required this.findings,
    required this.findingsByCandidateIdentity,
    required this.findingsByStatus,
    required this.findingsByDisposition,
  });

  final CanonicalBusinessTextClassificationIndex classifications;
  final List<CanonicalBusinessTextFinding> findings;

  final Map<String, CanonicalBusinessTextFinding> findingsByCandidateIdentity;

  final Map<
    CanonicalBusinessTextClassificationStatus,
    List<CanonicalBusinessTextFinding>
  >
  findingsByStatus;

  final Map<
    CanonicalBusinessTextFindingDisposition,
    List<CanonicalBusinessTextFinding>
  >
  findingsByDisposition;

  int get findingCount => findings.length;

  int get informationalCount => countForDisposition(
    CanonicalBusinessTextFindingDisposition.informational,
  );

  int get actionRequiredCount =>
      countForDisposition(
        CanonicalBusinessTextFindingDisposition.reviewRequired,
      ) +
      countForDisposition(CanonicalBusinessTextFindingDisposition.blocking);

  int countForStatus(CanonicalBusinessTextClassificationStatus status) {
    return findingsByStatus[status]!.length;
  }

  int countForDisposition(CanonicalBusinessTextFindingDisposition disposition) {
    return findingsByDisposition[disposition]!.length;
  }

  @override
  List<Object?> get props => <Object?>[classifications, findings];
}
