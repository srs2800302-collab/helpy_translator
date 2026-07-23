import 'dart:convert';

import '../../../canonical/application/contracts/canonical_business_text_candidate_extractor.dart';
import '../../../canonical/domain/entities/canonical_business_text_candidate.dart';
import '../../../canonical/domain/entities/canonical_business_text_candidate_index.dart';
import '../../../core/domain/evidence/source_evidence.dart';
import '../../../registry/domain/entities/registry_node.dart';
import '../../../registry/domain/entities/registry_snapshot.dart';
import '../../../registry/domain/entities/registry_structural_index.dart';

final class HelpyCanonicalBusinessTextCandidateExtractor
    implements CanonicalBusinessTextCandidateExtractor {
  const HelpyCanonicalBusinessTextCandidateExtractor();

  static final RegExp _fencePattern = RegExp(r'^ {0,3}(`{3,}|~{3,})');

  static final RegExp _unorderedListPattern = RegExp(
    r'^[-*+]\s+(?:\[[ xX]\]\s+)?(.+)$',
  );

  static final RegExp _orderedListPattern = RegExp(r'^\d+[.)]\s+(.+)$');

  static final RegExp _treeListPattern = RegExp(r'^[├└]──\s+(.+)$');

  static final RegExp _blockquotePattern = RegExp(r'^(?:>\s*)+(.+)$');

  static final RegExp _headingPattern = RegExp(r'^#{1,6}(?:\s+|$)');

  static final RegExp _htmlTagPattern = RegExp(r'^</?[A-Za-z][^>]*>$');

  static final RegExp _tableSeparatorCellPattern = RegExp(r'^:?-{3,}:?$');

  static final RegExp _sentenceEndingPattern = RegExp(r'[.!?…]$');

  static final RegExp _metadataLinePattern = RegExp(
    r'^(?:'
    r'Status|Registry Status|Decision Summary|Evidence|'
    r'Source|Revision|Owner|Version|'
    r'Статус|Доказательства|Источник|Версия'
    r'):',
    caseSensitive: false,
  );

  static final RegExp _statusDecorationPattern = RegExp(
    r'\s*(?:[—–-]\s*)?(?:✅\s*)?'
    r'(?:APPROVED|CLOSED|STORED|'
    r'DOCS(?:\s+VERIFIED)?|HISTORICAL)'
    r'(?:[\s+/—–-]+'
    r'(?:APPROVED|CLOSED|STORED|'
    r'DOCS(?:\s+VERIFIED)?|HISTORICAL|✅))*'
    r'\s*$',
  );

  static const Set<String> _excludedSectionLabels = <String>{
    'decision summary:',
    'evidence:',
    'evidence notes:',
    'примечания к доказательствам:',
    'recovery note:',
    'admin dependencies:',
    'required admin capabilities:',
    'decision:',
    'conclusion:',
    'electrical diagnostics:',
    'наследуемые правила:',
    'наследуемые правила',
  };

  @override
  CanonicalBusinessTextCandidateIndex extractCandidates(
    RegistrySnapshot snapshot,
  ) {
    final RegistryStructuralIndex structuralIndex = RegistryStructuralIndex(
      snapshot,
    );

    final List<CanonicalBusinessTextCandidate> candidates =
        <CanonicalBusinessTextCandidate>[];

    for (final RegistryNode node in structuralIndex.nodes) {
      final ownerId = node.businessScopeOwnerId;

      if (ownerId == null || _isExcludedNode(node)) {
        continue;
      }

      final Map<String, int> occurrencesByContextAndText = <String, int>{};

      final String? pathContentBlockIdentity = _contentBlockIdentityFromPath(
        node.path.segments,
      );

      final String? pathContentBlockLabel = pathContentBlockIdentity == null
          ? null
          : _contentBlockLabelForIdentity(pathContentBlockIdentity);

      final String? pathScenarioLabel = _scenarioLabelFromPath(
        node.path.segments,
      );

      String? activeContentBlockIdentity = pathContentBlockIdentity;

      String? activeContentBlockLabel = pathContentBlockLabel;

      String? activeScenarioLabel = pathScenarioLabel;

      int? activeContentBlockHeadingLevel;
      int? activeScenarioHeadingLevel;

      void addCandidate({
        required CanonicalBusinessTextCandidateKind kind,
        required String rawText,
        required String text,
        required int directContentLine,
        bool structuralLabel = false,
      }) {
        final String normalizedIdentityText = _normalizedCandidateText(text);

        if (normalizedIdentityText.isEmpty ||
            _metadataLinePattern.hasMatch(normalizedIdentityText)) {
          return;
        }

        final bool heading = kind == CanonicalBusinessTextCandidateKind.heading;

        final bool listItem =
            kind == CanonicalBusinessTextCandidateKind.listItem;

        final bool completedStatement =
            (kind == CanonicalBusinessTextCandidateKind.paragraph ||
                kind == CanonicalBusinessTextCandidateKind.blockquote) &&
            _sentenceEndingPattern.hasMatch(normalizedIdentityText);

        if (!heading && !listItem && !completedStatement && !structuralLabel) {
          return;
        }

        final String? scenarioIdentity = activeScenarioLabel == null
            ? null
            : _scenarioIdentity(ownerId.value, activeScenarioLabel);

        final String contextIdentity =
            '${activeContentBlockIdentity ?? 'content-block:none'}::'
            '${scenarioIdentity ?? 'scenario:none'}';

        final String occurrenceKey =
            '$contextIdentity::$normalizedIdentityText';

        final int occurrence =
            (occurrencesByContextAndText[occurrenceKey] ?? 0) + 1;

        occurrencesByContextAndText[occurrenceKey] = occurrence;

        final String encodedContext = Uri.encodeComponent(contextIdentity);

        final String encodedText = Uri.encodeComponent(normalizedIdentityText);

        candidates.add(
          CanonicalBusinessTextCandidate(
            identity:
                '${node.id.value}::canonical-business-text::'
                '$encodedContext::$encodedText::$occurrence',
            nodeId: node.id,
            businessScopeOwnerId: ownerId,
            path: node.path,
            sourceEvidence: _candidateSourceEvidence(
              node: node,
              directContentLine: directContentLine,
            ),
            kind: kind,
            rawText: rawText,
            text: normalizedIdentityText,
            directContentLine: directContentLine,
            contentBlockIdentity: activeContentBlockIdentity,
            contentBlockLabel: activeContentBlockLabel,
            scenarioIdentity: scenarioIdentity,
            scenarioLabel: activeScenarioLabel,
          ),
        );
      }

      addCandidate(
        kind: CanonicalBusinessTextCandidateKind.heading,
        rawText: node.path.segments.last,
        text: node.path.segments.last,
        directContentLine: 0,
      );

      if (node.content.trim().isEmpty) {
        continue;
      }

      final List<String> contentLines = const LineSplitter().convert(
        node.content,
      );

      String? activeFenceMarker;
      int activeFenceLength = 0;
      bool insideHtmlComment = false;
      String? activeSectionLabel;
      bool awaitingRootCategoryLabel = false;

      for (int lineIndex = 0; lineIndex < contentLines.length; lineIndex += 1) {
        final String rawLine = contentLines[lineIndex];
        final String trimmedLine = rawLine.trim();
        final int directContentLine = lineIndex + 1;

        if (trimmedLine.isEmpty) {
          continue;
        }

        if (insideHtmlComment) {
          if (trimmedLine.contains('-->')) {
            insideHtmlComment = false;
          }

          continue;
        }

        if (trimmedLine.startsWith('<!--')) {
          if (!trimmedLine.contains('-->')) {
            insideHtmlComment = true;
          }

          continue;
        }

        final RegExpMatch? fenceMatch = _fencePattern.firstMatch(rawLine);

        if (fenceMatch != null) {
          final String marker = fenceMatch.group(1)!;
          final String markerCharacter = marker[0];

          if (activeFenceMarker == null) {
            activeFenceMarker = markerCharacter;
            activeFenceLength = marker.length;
          } else if (markerCharacter == activeFenceMarker &&
              marker.length >= activeFenceLength) {
            activeFenceMarker = null;
            activeFenceLength = 0;
          }

          continue;
        }

        if (activeFenceMarker != null) {
          continue;
        }

        if (_headingPattern.hasMatch(trimmedLine)) {
          final int headingLevel = RegExp(
            r'^#+',
          ).firstMatch(trimmedLine)!.group(0)!.length;

          final String headingText = trimmedLine
              .replaceFirst(_headingPattern, '')
              .trim();

          final int? currentContentBlockHeadingLevel =
              activeContentBlockHeadingLevel;

          if (currentContentBlockHeadingLevel != null &&
              headingLevel <= currentContentBlockHeadingLevel) {
            activeContentBlockIdentity = pathContentBlockIdentity;

            activeContentBlockLabel = pathContentBlockLabel;

            activeContentBlockHeadingLevel = null;
          }

          final int? currentScenarioHeadingLevel = activeScenarioHeadingLevel;

          if (currentScenarioHeadingLevel != null &&
              headingLevel <= currentScenarioHeadingLevel) {
            activeScenarioLabel = pathScenarioLabel;
            activeScenarioHeadingLevel = null;
          }

          final String? scenarioLabel = _scenarioLabelForText(headingText);

          if (scenarioLabel != null) {
            activeScenarioLabel = scenarioLabel;
            activeScenarioHeadingLevel = headingLevel;
          }

          final String? contentBlockIdentity = _contentBlockIdentityForText(
            headingText,
          );

          if (contentBlockIdentity != null) {
            activeContentBlockIdentity = contentBlockIdentity;

            activeContentBlockLabel = _contentBlockLabelForIdentity(
              contentBlockIdentity,
            );

            activeContentBlockHeadingLevel = headingLevel;
          }

          activeSectionLabel = headingText.toLowerCase();

          awaitingRootCategoryLabel = false;
          continue;
        }

        if (_htmlTagPattern.hasMatch(trimmedLine)) {
          continue;
        }

        if (_isHorizontalRule(trimmedLine)) {
          activeSectionLabel = null;

          activeContentBlockIdentity = pathContentBlockIdentity;

          activeContentBlockLabel = pathContentBlockLabel;

          activeContentBlockHeadingLevel = null;

          activeScenarioLabel = pathScenarioLabel;
          activeScenarioHeadingLevel = null;

          awaitingRootCategoryLabel = false;
          continue;
        }

        if (_isTableSeparator(trimmedLine)) {
          continue;
        }

        final String structuralText = _normalizedStructuralText(trimmedLine);

        final String? structuralScenarioLabel = _scenarioLabelForText(
          structuralText,
        );

        final String? structuralContentBlockIdentity =
            _contentBlockIdentityForText(structuralText);

        if (structuralScenarioLabel != null ||
            structuralContentBlockIdentity != null) {
          if (structuralScenarioLabel != null) {
            activeScenarioLabel = structuralScenarioLabel;
            activeScenarioHeadingLevel = null;
          }

          if (structuralContentBlockIdentity != null) {
            activeContentBlockIdentity = structuralContentBlockIdentity;
            activeContentBlockLabel = _contentBlockLabelForIdentity(
              structuralContentBlockIdentity,
            );
            activeContentBlockHeadingLevel = null;
          }

          continue;
        }

        if (_isSectionLabel(structuralText)) {
          activeSectionLabel = structuralText.toLowerCase();
          awaitingRootCategoryLabel = activeSectionLabel == 'root category:';
          continue;
        }

        if (_isExcludedSection(activeSectionLabel)) {
          continue;
        }

        final bool followsRootCategoryLabel = awaitingRootCategoryLabel;
        awaitingRootCategoryLabel = false;

        final RegExpMatch? blockquoteMatch = _blockquotePattern.firstMatch(
          trimmedLine,
        );

        if (blockquoteMatch != null) {
          addCandidate(
            kind: CanonicalBusinessTextCandidateKind.blockquote,
            rawText: rawLine,
            text: blockquoteMatch.group(1)!,
            directContentLine: directContentLine,
          );

          continue;
        }

        final RegExpMatch? treeListMatch = _treeListPattern.firstMatch(
          trimmedLine,
        );

        if (treeListMatch != null) {
          addCandidate(
            kind: CanonicalBusinessTextCandidateKind.listItem,
            rawText: rawLine,
            text: treeListMatch.group(1)!,
            directContentLine: directContentLine,
          );

          continue;
        }

        final RegExpMatch? unorderedListMatch = _unorderedListPattern
            .firstMatch(trimmedLine);

        if (unorderedListMatch != null) {
          addCandidate(
            kind: CanonicalBusinessTextCandidateKind.listItem,
            rawText: rawLine,
            text: unorderedListMatch.group(1)!,
            directContentLine: directContentLine,
          );

          continue;
        }

        final RegExpMatch? orderedListMatch = _orderedListPattern.firstMatch(
          trimmedLine,
        );

        if (orderedListMatch != null) {
          addCandidate(
            kind: CanonicalBusinessTextCandidateKind.listItem,
            rawText: rawLine,
            text: orderedListMatch.group(1)!,
            directContentLine: directContentLine,
          );

          continue;
        }

        if (_isTableRow(trimmedLine)) {
          continue;
        }

        final String structuralContainerHeading = node.path.segments.last
            .trim()
            .toLowerCase();

        final bool structuralCategoryLabel =
            followsRootCategoryLabel ||
            (directContentLine == 1 &&
                (structuralContainerHeading == 'root category' ||
                    structuralContainerHeading ==
                        '${trimmedLine.toLowerCase()} registry content'));

        addCandidate(
          kind: CanonicalBusinessTextCandidateKind.paragraph,
          rawText: rawLine,
          text: trimmedLine,
          directContentLine: directContentLine,
          structuralLabel: structuralCategoryLabel,
        );
      }
    }

    return CanonicalBusinessTextCandidateIndex(
      projectId: snapshot.projectId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: snapshot.sourceRevision,
      sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      candidates: candidates,
    );
  }

  List<SourceEvidence> _candidateSourceEvidence({
    required RegistryNode node,
    required int directContentLine,
  }) {
    return <SourceEvidence>[
      for (final SourceEvidence evidence in node.sourceEvidence)
        SourceEvidence(
          sourceDocumentPath: evidence.sourceDocumentPath,
          sourceSnapshotFingerprint: evidence.sourceSnapshotFingerprint,
          headingPath: evidence.headingPath,
          startLine: evidence.startLine + directContentLine,
          endLine: evidence.startLine + directContentLine,
        ),
    ];
  }

  String? _contentBlockIdentityFromPath(Iterable<String> path) {
    String? identity;

    for (final String segment in path) {
      identity = _contentBlockIdentityForText(segment) ?? identity;
    }

    return identity;
  }

  String? _contentBlockIdentityForText(String text) {
    final String normalized = text.trim().replaceAll(RegExp(r'[:\s]+$'), '');

    final List<String> segments = normalized.split(RegExp(r'\s+[—–-]\s+'));

    return _contentBlockIdentityForLabel(segments.first);
  }

  String? _contentBlockIdentityForLabel(String label) {
    final String normalized = label
        .trim()
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'[:—–-]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ');

    const Set<String> photoQuestions = <String>{
      'фото-вопросы',
      'фото вопросы',
      'обязательные фото-вопросы',
      'обязательные фото вопросы',
      'дополнительные фото-вопросы',
      'дополнительные фото вопросы',
      'photo questions',
      'required photo questions',
      'additional photo questions',
      'photo requirements',
    };

    if (photoQuestions.contains(normalized)) {
      return 'helpy.business-content.photo-questions';
    }

    const Set<String> questions = <String>{
      'вопросы',
      'вопросы клиенту',
      'вопросы к клиенту',
      'questions',
      'client questions',
      'customer questions',
    };

    if (questions.contains(normalized)) {
      return 'helpy.business-content.questions';
    }

    const Set<String> clientRules = <String>{
      'правила клиента',
      'правила для клиента',
      'правила клиенту',
      'client rules',
      'customer rules',
    };

    if (clientRules.contains(normalized)) {
      return 'helpy.business-content.client-rules';
    }

    const Set<String> masterRules = <String>{
      'правила мастера',
      'правила для мастера',
      'правила исполнителя',
      'правила для исполнителя',
      'master rules',
      'contractor rules',
      'master workflow',
    };

    if (masterRules.contains(normalized)) {
      return 'helpy.business-content.master-rules';
    }

    return null;
  }

  String _contentBlockLabelForIdentity(String identity) {
    return switch (identity) {
      'helpy.business-content.questions' => 'Вопросы',
      'helpy.business-content.photo-questions' => 'Фото-вопросы',
      'helpy.business-content.client-rules' => 'Правила клиента',
      'helpy.business-content.master-rules' => 'Правила мастера',
      _ => throw StateError(
        'Unsupported Helpy business content block: '
        '$identity',
      ),
    };
  }

  String? _scenarioLabelFromPath(Iterable<String> path) {
    for (final String segment in path.toList(growable: false).reversed) {
      final String? scenarioLabel = _scenarioLabelForText(segment);

      if (scenarioLabel != null) {
        return scenarioLabel;
      }
    }

    return null;
  }

  String? _scenarioLabelForText(String text) {
    return _combinedContentBlockScenarioLabel(text) ??
        _explicitScenarioLabel(text);
  }

  String? _combinedContentBlockScenarioLabel(String text) {
    final String normalized = text.trim().replaceAll(RegExp(r'[:\s]+$'), '');

    final List<String> segments = normalized.split(RegExp(r'\s+[—–-]\s+'));

    if (segments.length < 2 ||
        _contentBlockIdentityForLabel(segments.first) == null) {
      return null;
    }

    final String scenarioLabel = segments.last.trim();

    return scenarioLabel.isEmpty ? null : scenarioLabel;
  }

  String? _explicitScenarioLabel(String text) {
    final String normalized = text.trim().replaceAll(RegExp(r'[:\s]+$'), '');

    final List<RegExp> patterns = <RegExp>[
      RegExp(
        r'^(?:сценарий|scenario)'
        r'(?:\s+\d+)?\s*'
        r'(?:[:—–-]\s*)?'
        r'[«"]?(.+?)[»"]?$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(?:если\s+выбрано|if\s+selected)'
        r'\s*[«"]?(.+?)[»"]?$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(?:для\s+сценария|for\s+scenario)'
        r'\s*[«"]?(.+?)[»"]?$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(?:тип\s+работ|work\s+type)'
        r'\s*[:—–-]\s*(.+)$',
        caseSensitive: false,
      ),
    ];

    for (final RegExp pattern in patterns) {
      final RegExpMatch? match = pattern.firstMatch(normalized);

      if (match == null) {
        continue;
      }

      final String scenarioLabel = match.group(1)!.trim();

      if (scenarioLabel.isNotEmpty) {
        return scenarioLabel;
      }
    }

    return null;
  }

  String _scenarioIdentity(String ownerId, String scenarioLabel) {
    final String normalizedLabel = scenarioLabel
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');

    return '$ownerId::scenario::'
        '${Uri.encodeComponent(normalizedLabel)}';
  }

  String _normalizedCandidateText(String text) {
    String value = text.trim().replaceAll(RegExp(r'\s+'), ' ');

    value = value.replaceFirst(_statusDecorationPattern, '');

    return value.trim();
  }

  String _normalizedStructuralText(String rawLine) {
    String value = rawLine.trim();

    final RegExpMatch? blockquoteMatch = _blockquotePattern.firstMatch(value);

    if (blockquoteMatch != null) {
      value = blockquoteMatch.group(1)!.trim();
    }

    final RegExpMatch? treeListMatch = _treeListPattern.firstMatch(value);

    if (treeListMatch != null) {
      value = treeListMatch.group(1)!.trim();
    }

    final RegExpMatch? unorderedListMatch = _unorderedListPattern.firstMatch(
      value,
    );

    if (unorderedListMatch != null) {
      value = unorderedListMatch.group(1)!.trim();
    }

    final RegExpMatch? orderedListMatch = _orderedListPattern.firstMatch(value);

    if (orderedListMatch != null) {
      value = orderedListMatch.group(1)!.trim();
    }

    return value;
  }

  bool _isSectionLabel(String text) {
    return text.endsWith(':') &&
        text.length <= 120 &&
        !RegExp(r'[.!?…]\s*:$').hasMatch(text);
  }

  bool _isExcludedSection(String? sectionLabel) {
    return sectionLabel != null &&
        _excludedSectionLabels.contains(sectionLabel);
  }

  bool _isExcludedNode(RegistryNode node) {
    return node.path.segments.any(
      (String segment) =>
          segment.trim().toLowerCase().endsWith('admin dependencies'),
    );
  }

  bool _isHorizontalRule(String line) {
    final String compact = line.replaceAll(RegExp(r'\s+'), '');

    return RegExp(r'^-{3,}$').hasMatch(compact) ||
        RegExp(r'^\*{3,}$').hasMatch(compact) ||
        RegExp(r'^_{3,}$').hasMatch(compact);
  }

  bool _isTableRow(String line) {
    return line.contains('|') && (line.startsWith('|') || line.endsWith('|'));
  }

  bool _isTableSeparator(String line) {
    if (!_isTableRow(line)) {
      return false;
    }

    final List<String> cells = _tableCells(line);

    return cells.isNotEmpty &&
        cells.every((String cell) => _tableSeparatorCellPattern.hasMatch(cell));
  }

  List<String> _tableCells(String line) {
    String content = line.trim();

    if (content.startsWith('|')) {
      content = content.substring(1);
    }

    if (content.endsWith('|')) {
      content = content.substring(0, content.length - 1);
    }

    return content
        .split('|')
        .map((String cell) => cell.trim())
        .where((String cell) => cell.isNotEmpty)
        .toList(growable: false);
  }
}
