import 'dart:convert';

import '../../../canonical/application/contracts/canonical_business_text_candidate_extractor.dart';
import '../../../canonical/domain/entities/canonical_business_text_candidate.dart';
import '../../../canonical/domain/entities/canonical_business_text_candidate_index.dart';
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

      final Map<String, int> occurrencesByIdentityText = <String, int>{};

      void addCandidate({
        required CanonicalBusinessTextCandidateKind kind,
        required String rawText,
        required String text,
        required int directContentLine,
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

        if (!heading && !listItem && !completedStatement) {
          return;
        }

        final int occurrence =
            (occurrencesByIdentityText[normalizedIdentityText] ?? 0) + 1;

        occurrencesByIdentityText[normalizedIdentityText] = occurrence;

        final String encodedText = Uri.encodeComponent(normalizedIdentityText);

        candidates.add(
          CanonicalBusinessTextCandidate(
            identity:
                '${node.id.value}::canonical-business-text::'
                '$encodedText::$occurrence',
            nodeId: node.id,
            businessScopeOwnerId: ownerId,
            path: node.path,
            sourceEvidence: node.sourceEvidence,
            kind: kind,
            rawText: rawText,
            text: normalizedIdentityText,
            directContentLine: directContentLine,
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
          activeSectionLabel = trimmedLine
              .replaceFirst(_headingPattern, '')
              .trim()
              .toLowerCase();
          continue;
        }

        if (_htmlTagPattern.hasMatch(trimmedLine)) {
          continue;
        }

        if (_isHorizontalRule(trimmedLine)) {
          activeSectionLabel = null;
          continue;
        }

        if (_isTableSeparator(trimmedLine)) {
          continue;
        }

        final String structuralText = _normalizedStructuralText(trimmedLine);

        if (_isSectionLabel(structuralText)) {
          activeSectionLabel = structuralText.toLowerCase();
          continue;
        }

        if (_isExcludedSection(activeSectionLabel)) {
          continue;
        }

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

        addCandidate(
          kind: CanonicalBusinessTextCandidateKind.paragraph,
          rawText: rawLine,
          text: trimmedLine,
          directContentLine: directContentLine,
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
