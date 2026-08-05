import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../domain/entities/matrix_assessment.dart';
import '../../domain/entities/semantic_observation.dart';
import '../../domain/entities/translation_matrix_result.dart';
import '../../domain/entities/translation_route.dart';
import '../../domain/entities/translation_route_result.dart';

final class TranslationMatrixResultView extends StatefulWidget {
  const TranslationMatrixResultView({required this.result, super.key});

  final TranslationMatrixResult result;

  @override
  State<TranslationMatrixResultView> createState() =>
      _TranslationMatrixResultViewState();
}

final class _TranslationMatrixResultViewState
    extends State<TranslationMatrixResultView> {
  bool _isExpanded = false;

  String get _resultId =>
      widget.result.createdAt.microsecondsSinceEpoch.toString();

  String get _storageIdentifier =>
      'translator-result-expansion-state-$_resultId';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restoreExpansionState();
  }

  @override
  void didUpdateWidget(covariant TranslationMatrixResultView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.result.createdAt.microsecondsSinceEpoch !=
        widget.result.createdAt.microsecondsSinceEpoch) {
      _isExpanded = false;
      _restoreExpansionState();
    }
  }

  void _restoreExpansionState() {
    final PageStorageBucket? bucket = PageStorage.maybeOf(context);

    if (bucket == null) {
      return;
    }

    final Object? storedValue = bucket.readState(
      context,
      identifier: _storageIdentifier,
    );

    _isExpanded = storedValue is bool ? storedValue : false;
  }

  void _handleExpansionChanged(bool isExpanded) {
    if (_isExpanded == isExpanded) {
      return;
    }

    setState(() {
      _isExpanded = isExpanded;
    });

    PageStorage.maybeOf(
      context,
    )?.writeState(context, isExpanded, identifier: _storageIdentifier);
  }

  @override
  Widget build(BuildContext context) {
    final TranslationMatrixResult result = widget.result;
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final MatrixAssessment assessment = result.assessment;
    final List<SemanticObservation> attentionObservations = assessment
        .observations
        .where(_requiresAttention)
        .toList(growable: false);
    final List<SemanticObservation> preservedObservations = assessment
        .observations
        .where(
          (SemanticObservation observation) => !_requiresAttention(observation),
        )
        .toList(growable: false);

    return Card(
      key: ValueKey<String>(
        'translator-result-${result.createdAt.microsecondsSinceEpoch}',
      ),
      color: _verdictColor(assessment.verdict),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        key: ValueKey<String>('translator-result-expansion-$_resultId'),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: _handleExpansionChanged,
        leading: Text(
          _verdictIcon(assessment.verdict),
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          l10n.verdictLabel(assessment.verdict.name),
          key: ValueKey<String>('translator-result-header-$_resultId'),
        ),
        subtitle: Text(
          result.sourceText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const ValueKey<String>('translator-copy-all-button'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _copyText(result)));

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.copied)));
              },
              icon: const Icon(Icons.copy_outlined),
              label: Text(l10n.copyAll),
            ),
          ),
          _TextSection(
            label: '${l10n.sourceText} (${result.sourceLanguage.code})',
            value: result.sourceText,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.auditCoverageLabel(
                result.auditCoverage.name,
                result.routes.length,
              ),
              key: const ValueKey<String>('translator-audit-coverage'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const Divider(),
          for (final TranslationRouteResult route in result.routes) ...<Widget>[
            _RouteSection(route: route),
            if (route != result.routes.last) const Divider(height: 24),
          ],
          const Divider(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.finalMatrixAssessment,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.auditPassDisclosure,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 10),
          if (assessment.observations.isEmpty) ...<Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.noConcreteIssues),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.noProofNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ] else ...<Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.attentionObservationCount(attentionObservations.length),
                key: const ValueKey<String>(
                  'translator-attention-observation-count',
                ),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            if (attentionObservations.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              ..._buildObservationGroups(
                context: context,
                observations: attentionObservations,
                bucketId: 'attention',
              ),
            ],
            if (preservedObservations.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              ExpansionTile(
                key: const ValueKey<String>(
                  'translator-preserved-observations',
                ),
                initiallyExpanded: false,
                maintainState: false,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 4),
                title: Text(
                  l10n.preservedObservationCount(preservedObservations.length),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                children: _buildObservationGroups(
                  context: context,
                  observations: preservedObservations,
                  bucketId: 'preserved',
                ),
              ),
            ],
          ],
          if (assessment.limitations.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.limitations,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 4),
            for (final String limitation in assessment.limitations)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('• ${l10n.auditLimitationLabel(limitation)}'),
              ),
          ],
        ],
      ),
    );
  }

  static bool _requiresAttention(SemanticObservation observation) {
    return observation.preservation != MeaningPreservation.preserved ||
        observation.verificationStatus !=
            ObservationVerificationStatus.confirmed;
  }

  static List<Widget> _buildObservationGroups({
    required BuildContext context,
    required List<SemanticObservation> observations,
    required String bucketId,
  }) {
    final Map<String, List<SemanticObservation>> grouped =
        <String, List<SemanticObservation>>{};

    for (final SemanticObservation observation in observations) {
      grouped
          .putIfAbsent(observation.routeId, () => <SemanticObservation>[])
          .add(observation);
    }

    return grouped.entries
        .map(
          (MapEntry<String, List<SemanticObservation>> entry) =>
              _ObservationGroup(
                key: ValueKey<String>(
                  'translator-observation-group-$bucketId-${entry.key}',
                ),
                bucketId: bucketId,
                routeId: entry.key,
                observations: entry.value,
              ),
        )
        .toList(growable: false);
  }

  static String _copyText(TranslationMatrixResult result) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('SOURCE (${result.sourceLanguage.code}):')
      ..writeln(result.sourceText)
      ..writeln()
      ..writeln(
        'AUDIT COVERAGE: ${result.auditCoverage.name} '
        '(${result.routes.length} routes)',
      )
      ..writeln();

    for (final TranslationRouteResult route in result.routes) {
      buffer
        ..writeln('${route.route.id} [${route.route.role.name}]:')
        ..writeln(route.translatedText)
        ..writeln();
    }

    buffer
      ..writeln('FINAL MATRIX ASSESSMENT:')
      ..writeln(result.assessment.verdict.name);

    if (result.assessment.observations.isNotEmpty) {
      buffer.writeln();

      for (final SemanticObservation observation
          in result.assessment.observations) {
        buffer
          ..writeln('${observation.routeId} [${observation.routeRole.name}]')
          ..writeln('CANDIDATE: ${_tuple(observation)}')
          ..writeln('VERIFICATION: ${observation.verificationStatus.name}');

        if (observation.hasVerifierTuple) {
          buffer.writeln('VERIFIER: ${_verifierTuple(observation)}');
        }

        if (observation.sourceExcerpt != null) {
          buffer.writeln('SOURCE: ${observation.sourceExcerpt}');
        }

        if (observation.targetExcerpt != null) {
          buffer.writeln('TARGET: ${observation.targetExcerpt}');
        }

        buffer.writeln();
      }
    }

    if (result.assessment.limitations.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('LIMITATIONS:');

      for (final String limitation in result.assessment.limitations) {
        buffer.writeln('- $limitation');
      }
    }

    return buffer.toString().trim();
  }

  static String _tuple(SemanticObservation observation) {
    return '${observation.relation.code} / '
        '${observation.dimension.code} / '
        '${observation.preservation.code}';
  }

  static String? _verifierTuple(SemanticObservation observation) {
    final SemanticRelation? relation = observation.verifierRelation;
    final SemanticDimension? dimension = observation.verifierDimension;
    final MeaningPreservation? preservation = observation.verifierPreservation;

    if (relation == null || dimension == null || preservation == null) {
      return null;
    }

    return '${relation.code} / ${dimension.code} / ${preservation.code}';
  }

  static String _verdictIcon(MatrixVerdict verdict) {
    return switch (verdict) {
      MatrixVerdict.noCriticalDriftDetected => '✅',
      MatrixVerdict.acceptableVariation => '🟢',
      MatrixVerdict.reviewRequired => '🟡',
      MatrixVerdict.unreliable => '🔴',
      MatrixVerdict.indeterminate => '❌',
    };
  }

  static Color _verdictColor(MatrixVerdict verdict) {
    return switch (verdict) {
      MatrixVerdict.noCriticalDriftDetected => Colors.green.shade50,
      MatrixVerdict.acceptableVariation => Colors.lightGreen.shade50,
      MatrixVerdict.reviewRequired => Colors.yellow.shade50,
      MatrixVerdict.unreliable => Colors.red.shade50,
      MatrixVerdict.indeterminate => Colors.red.shade50,
    };
  }
}

final class _RouteSection extends StatelessWidget {
  const _RouteSection({required this.route});

  final TranslationRouteResult route;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final String roleLabel = switch (route.route.role) {
      TranslationRouteRole.primary => l10n.primaryTranslation,
      TranslationRouteRole.crossCheck => l10n.crossCheckTranslation,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${route.route.id} · $roleLabel',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        SelectableText(route.translatedText),
      ],
    );
  }
}

final class _ObservationGroup extends StatelessWidget {
  const _ObservationGroup({
    required this.bucketId,
    required this.routeId,
    required this.observations,
    super.key,
  });

  final String bucketId;
  final String routeId;
  final List<SemanticObservation> observations;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final TranslationRouteRole routeRole = observations.first.routeRole;
    final String roleLabel = switch (routeRole) {
      TranslationRouteRole.primary => l10n.primaryTranslation,
      TranslationRouteRole.crossCheck => l10n.crossCheckTranslation,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Text(
              '$routeId · $roleLabel',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const Divider(height: 1),
          for (int index = 0; index < observations.length; index++) ...<Widget>[
            _ObservationTile(
              tileKey: ValueKey<String>(
                'translator-observation-$bucketId-$routeId-$index',
              ),
              observation: observations[index],
            ),
            if (index != observations.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

final class _ObservationTile extends StatelessWidget {
  const _ObservationTile({required this.tileKey, required this.observation});

  final Key tileKey;
  final SemanticObservation observation;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final bool isCrossCheck =
        observation.routeRole == TranslationRouteRole.crossCheck;
    final String candidateTuple =
        '${observation.relation.code} / '
        '${observation.dimension.code} / '
        '${observation.preservation.code}';
    final String? verifierTuple =
        observation.verifierRelation == null ||
            observation.verifierDimension == null ||
            observation.verifierPreservation == null
        ? null
        : '${observation.verifierRelation!.code} / '
              '${observation.verifierDimension!.code} / '
              '${observation.verifierPreservation!.code}';

    return ExpansionTile(
      key: tileKey,
      initiallyExpanded: false,
      maintainState: false,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Text(
        '${l10n.observationDimensionLabel(observation.dimension.name)} · '
        '${l10n.meaningPreservationLabel(observation.preservation.name)}',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      subtitle: Text(
        _excerptSummary(context),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.observationRelationLabel(observation.relation.name),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(
            l10n.observationEvidenceExplanation(
              preservationName: observation.preservation.name,
              dimensionName: observation.dimension.name,
              verificationStatusName: observation.verificationStatus.name,
              isCrossCheck: isCrossCheck,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.observationVerificationLabel(
              statusName: observation.verificationStatus.name,
              candidateTuple: candidateTuple,
              verifierTuple: verifierTuple,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (observation.sourceExcerpt != null) ...<Widget>[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.sourceExcerpt,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(observation.sourceExcerpt!),
          ),
        ],
        if (observation.targetExcerpt != null) ...<Widget>[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.targetExcerpt,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(observation.targetExcerpt!),
          ),
        ],
      ],
    );
  }

  String _excerptSummary(BuildContext context) {
    final String? source = observation.sourceExcerpt;
    final String? target = observation.targetExcerpt;

    if (source != null && target != null) {
      return '$source → $target';
    }

    if (source != null) {
      return source;
    }

    if (target != null) {
      return target;
    }

    return context.rsL10n.observationRelationLabel(observation.relation.name);
  }
}

final class _TextSection extends StatelessWidget {
  const _TextSection({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}
