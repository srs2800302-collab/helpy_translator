import 'package:flutter/material.dart';

import '../../../core/application/related_context/prepare_registry_related_context.dart';
import '../../../core/application/related_context/prepare_registry_resolved_related_context.dart';
import '../../../core/application/related_context/registry_related_context.dart';
import '../../../core/application/related_context/registry_resolved_related_context.dart';
import '../../../core/domain/entities/registry_entity.dart';
import '../../../core/domain/value_objects/registry_relation.dart';
import '../../../presentation/language/registry_studio_ui_labels.dart';
import '../../../presentation/language/registry_studio_ui_language.dart';

final class RegistryRelatedContextPreparationScreen extends StatefulWidget {
  const RegistryRelatedContextPreparationScreen({
    required this.uiLanguage,
    required this.primary,
    required this.relations,
    required this.availableRelatedEntities,
    required this.prepareRegistryRelatedContext,
    required this.prepareRegistryResolvedRelatedContext,
    super.key,
  });

  final RegistryStudioUiLanguage uiLanguage;
  final RegistryEntity primary;
  final Iterable<RegistryRelation> relations;
  final Iterable<RegistryEntity> availableRelatedEntities;
  final PrepareRegistryRelatedContext prepareRegistryRelatedContext;
  final PrepareRegistryResolvedRelatedContext
  prepareRegistryResolvedRelatedContext;

  @override
  State<RegistryRelatedContextPreparationScreen> createState() =>
      _RegistryRelatedContextPreparationScreenState();
}

final class _RegistryRelatedContextPreparationScreenState
    extends State<RegistryRelatedContextPreparationScreen> {
  static const Key prepareButtonKey = Key(
    'registry_related_context_prepare_button',
  );
  static const Key primaryEntityCardKey = Key(
    'registry_related_context_primary_entity_card',
  );
  static const Key relatedContextCardKey = Key(
    'registry_related_context_result_card',
  );
  static const Key resolvedContextCardKey = Key(
    'registry_resolved_related_context_result_card',
  );
  static const Key errorTextKey = Key('registry_related_context_error_text');

  RegistryRelatedContext? _relatedContext;
  RegistryResolvedRelatedContext? _resolvedRelatedContext;
  String? _errorMessage;

  void _prepareContext() {
    final RegistryStudioRelatedContextPreparationLabels labels =
        RegistryStudioUiLabels.forLanguage(
          widget.uiLanguage,
        ).relatedContextPreparation;

    try {
      final RegistryRelatedContext relatedContext = widget
          .prepareRegistryRelatedContext(
            primary: widget.primary,
            relations: widget.relations,
          );

      final RegistryResolvedRelatedContext resolvedRelatedContext = widget
          .prepareRegistryResolvedRelatedContext(
            base: relatedContext,
            availableRelatedEntities: widget.availableRelatedEntities,
          );

      setState(() {
        _relatedContext = relatedContext;
        _resolvedRelatedContext = resolvedRelatedContext;
        _errorMessage = null;
      });
    } on ArgumentError catch (error) {
      setState(() {
        _relatedContext = null;
        _resolvedRelatedContext = null;
        _errorMessage =
            '${labels.preparationFailedTitle}: ${error.message.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final RegistryStudioRelatedContextPreparationLabels labels =
        RegistryStudioUiLabels.forLanguage(
          widget.uiLanguage,
        ).relatedContextPreparation;
    final RegistryRelatedContext? relatedContext = _relatedContext;
    final RegistryResolvedRelatedContext? resolvedRelatedContext =
        _resolvedRelatedContext;
    final String? errorMessage = _errorMessage;

    return Scaffold(
      appBar: AppBar(title: Text(labels.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _RegistryEntityCard(
            key: primaryEntityCardKey,
            title: labels.primaryEntityTitle,
            labels: labels,
            entity: widget.primary,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: prepareButtonKey,
            onPressed: _prepareContext,
            child: Text(labels.prepareButton),
          ),
          if (errorMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            _RelatedContextErrorMessage(message: errorMessage),
          ],
          if (relatedContext != null) ...<Widget>[
            const SizedBox(height: 16),
            _RegistryRelatedContextCard(
              key: relatedContextCardKey,
              labels: labels,
              context: relatedContext,
            ),
          ],
          if (resolvedRelatedContext != null) ...<Widget>[
            const SizedBox(height: 16),
            _RegistryResolvedRelatedContextCard(
              key: resolvedContextCardKey,
              labels: labels,
              context: resolvedRelatedContext,
            ),
          ],
        ],
      ),
    );
  }
}

final class _RelatedContextErrorMessage extends StatelessWidget {
  const _RelatedContextErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        key: _RegistryRelatedContextPreparationScreenState.errorTextKey,
        padding: const EdgeInsets.all(12),
        child: Text(message),
      ),
    );
  }
}

final class _RegistryEntityCard extends StatelessWidget {
  const _RegistryEntityCard({
    required this.title,
    required this.labels,
    required this.entity,
    super.key,
  });

  final String title;
  final RegistryStudioRelatedContextPreparationLabels labels;
  final RegistryEntity entity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _TextValueRow(
              label: labels.primaryEntityLabel,
              value: entity.id.value,
            ),
            _TextValueRow(
              label: labels.pathLabel,
              value: entity.path.segments.join(' / '),
            ),
            _TextValueRow(label: labels.kindLabel, value: entity.kind.kindId),
          ],
        ),
      ),
    );
  }
}

final class _RegistryRelatedContextCard extends StatelessWidget {
  const _RegistryRelatedContextCard({
    required this.labels,
    required this.context,
    super.key,
  });

  final RegistryStudioRelatedContextPreparationLabels labels;
  final RegistryRelatedContext context;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              labels.relatedContextTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _TextValueRow(
              label: labels.matchedRelationsLabel,
              value: _formatItems(
                this.context.matchedRelations.map(_relationLabel),
                labels.noItemsLabel,
              ),
            ),
            _TextValueRow(
              label: labels.relatedEntityIdsLabel,
              value: _formatItems(
                this.context.relatedEntityIds.map((id) => id.value),
                labels.noItemsLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _RegistryResolvedRelatedContextCard extends StatelessWidget {
  const _RegistryResolvedRelatedContextCard({
    required this.labels,
    required this.context,
    super.key,
  });

  final RegistryStudioRelatedContextPreparationLabels labels;
  final RegistryResolvedRelatedContext context;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              labels.resolvedContextTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _TextValueRow(
              label: labels.resolvedRelatedEntitiesLabel,
              value: _formatItems(
                this.context.resolvedRelatedEntities.map(
                  (entity) => entity.id.value,
                ),
                labels.noItemsLabel,
              ),
            ),
            _TextValueRow(
              label: labels.missingRelatedEntityIdsLabel,
              value: _formatItems(
                this.context.missingRelatedEntityIds.map((id) => id.value),
                labels.noItemsLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TextValueRow extends StatelessWidget {
  const _TextValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label:\n$value'),
    );
  }
}

String _relationLabel(RegistryRelation relation) {
  return '${relation.sourceEntityId.value} -> '
      '${relation.targetEntityId.value} '
      '[${relation.meaning.value}]';
}

String _formatItems(Iterable<String> values, String emptyLabel) {
  final List<String> normalizedValues = values.toList(growable: false);

  if (normalizedValues.isEmpty) {
    return emptyLabel;
  }

  return normalizedValues.join('\n');
}
