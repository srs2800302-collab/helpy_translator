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

  static final RegExp _blockquotePattern = RegExp(r'^(?:>\s*)+(.+)$');

  static final RegExp _headingPattern = RegExp(r'^#{1,6}(?:\s+|$)');

  static final RegExp _htmlTagPattern = RegExp(r'^</?[A-Za-z][^>]*>$');

  static final RegExp _tableSeparatorCellPattern = RegExp(r'^:?-{3,}:?$');

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

      if (ownerId == null) {
        continue;
      }

      final Map<String, int> occurrencesByIdentityText = <String, int>{};

      void addCandidate({
        required CanonicalBusinessTextCandidateKind kind,
        required String rawText,
        required String text,
        required int directContentLine,
      }) {
        final String normalizedIdentityText = text.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );

        if (normalizedIdentityText.isEmpty) {
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

      final String heading = node.path.segments.last;

      addCandidate(
        kind: CanonicalBusinessTextCandidateKind.heading,
        rawText: heading,
        text: heading,
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

        if (_headingPattern.hasMatch(trimmedLine) ||
            _htmlTagPattern.hasMatch(trimmedLine) ||
            _isHorizontalRule(trimmedLine) ||
            _isTableSeparator(trimmedLine)) {
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
          final String tableText = _tableText(trimmedLine);

          if (tableText.isNotEmpty) {
            addCandidate(
              kind: CanonicalBusinessTextCandidateKind.tableRow,
              rawText: rawLine,
              text: tableText,
              directContentLine: directContentLine,
            );
          }

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

  String _tableText(String line) {
    return _tableCells(line).join(' | ').trim();
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
