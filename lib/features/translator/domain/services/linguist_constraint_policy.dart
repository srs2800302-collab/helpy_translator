import '../entities/matrix_assessment.dart';
import '../entities/primary_linguist_report.dart';

abstract interface class LinguistConstraintPolicy {
  MatrixAssessment apply({
    required MatrixAssessment matrixAssessment,
    required PrimaryLinguistReport linguistReport,
  });
}

/// Applies Linguist evidence only as a conservative constraint.
///
/// Linguist evidence can preserve or lower trust in the matrix assessment.
/// It can never promote a matrix verdict to a more positive verdict.
final class ConservativeLinguistConstraintPolicy
    implements LinguistConstraintPolicy {
  const ConservativeLinguistConstraintPolicy();

  static const String unresolvedLimitation = 'LINGUIST_UNRESOLVED';
  static const String invalidEvidenceLimitation = 'LINGUIST_EVIDENCE_INVALID';
  static const String emptyReportLimitation = 'LINGUIST_REPORT_EMPTY';

  @override
  MatrixAssessment apply({
    required MatrixAssessment matrixAssessment,
    required PrimaryLinguistReport linguistReport,
  }) {
    final List<String> limitations = List<String>.of(
      matrixAssessment.limitations,
    );
    final Set<String> seenLimitations = limitations.toSet();

    for (final String limitation in linguistReport.limitations) {
      _appendUnique(
        limitation: limitation,
        target: limitations,
        seen: seenLimitations,
      );
    }

    bool hasCompleteIncompatibility = false;
    bool hasUncertainty = linguistReport.limitations.isNotEmpty;

    if (linguistReport.assessments.isEmpty) {
      hasUncertainty = true;

      if (linguistReport.limitations.isEmpty) {
        _appendUnique(
          limitation: emptyReportLimitation,
          target: limitations,
          seen: seenLimitations,
        );
      }
    }

    for (final PrimaryLinguistAssessment assessment
        in linguistReport.assessments) {
      for (final String limitation in assessment.limitations) {
        _appendUnique(
          limitation: limitation,
          target: limitations,
          seen: seenLimitations,
        );
      }

      switch (assessment.status) {
        case PrimaryLinguistStatus.compatible:
          if (assessment.sourceExcerpt != null ||
              assessment.targetExcerpt != null ||
              assessment.limitations.isNotEmpty) {
            hasUncertainty = true;
            _appendUnique(
              limitation: invalidEvidenceLimitation,
              target: limitations,
              seen: seenLimitations,
            );
          }

        case PrimaryLinguistStatus.incompatible:
          if (assessment.hasCompleteDifferenceEvidence &&
              assessment.limitations.isEmpty) {
            hasCompleteIncompatibility = true;
          } else {
            hasUncertainty = true;
            _appendUnique(
              limitation: invalidEvidenceLimitation,
              target: limitations,
              seen: seenLimitations,
            );
          }

        case PrimaryLinguistStatus.unresolved:
          hasUncertainty = true;
          _appendUnique(
            limitation: unresolvedLimitation,
            target: limitations,
            seen: seenLimitations,
          );
      }
    }

    final MatrixVerdict verdict;

    if (hasUncertainty && _isPositive(matrixAssessment.verdict)) {
      verdict = MatrixVerdict.indeterminate;
    } else if (hasCompleteIncompatibility &&
        _isPositive(matrixAssessment.verdict)) {
      verdict = MatrixVerdict.reviewRequired;
    } else {
      verdict = matrixAssessment.verdict;
    }

    return MatrixAssessment(
      verdict: verdict,
      observations: List.unmodifiable(matrixAssessment.observations),
      limitations: List<String>.unmodifiable(limitations),
    );
  }

  static bool _isPositive(MatrixVerdict verdict) {
    return verdict == MatrixVerdict.noCriticalDriftDetected ||
        verdict == MatrixVerdict.acceptableVariation;
  }

  static void _appendUnique({
    required String limitation,
    required List<String> target,
    required Set<String> seen,
  }) {
    final String normalized = limitation.trim();

    if (normalized.isEmpty || !seen.add(normalized)) {
      return;
    }

    target.add(normalized);
  }
}
