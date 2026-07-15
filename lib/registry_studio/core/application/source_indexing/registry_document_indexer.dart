import 'registry_document_node.dart';

final class RegistryDocumentIndexer {
  const RegistryDocumentIndexer();

  static final RegExp _headingPattern = RegExp(r'^(#{1,6})\s+(.+?)\s*$');
  static final RegExp _openingFencePattern = RegExp(r'^(`{3,}|~{3,}).*$');

  List<RegistryDocumentNode> index(String source) {
    if (source.trim().isEmpty) {
      throw const FormatException(
        'Registry document source must not be empty.',
      );
    }

    final List<_MutableRegistryDocumentNode> roots =
        <_MutableRegistryDocumentNode>[];
    final List<_MutableRegistryDocumentNode> stack =
        <_MutableRegistryDocumentNode>[];

    int lineStart = 0;
    int lineNumber = 1;
    int lineCount = 0;
    String? activeFenceCharacter;
    int activeFenceLength = 0;

    while (lineStart < source.length) {
      final int newlineOffset = source.indexOf('\n', lineStart);
      final int lineEnd = newlineOffset == -1 ? source.length : newlineOffset;

      String line = source.substring(lineStart, lineEnd);

      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }

      lineCount = lineNumber;

      final String leftTrimmedLine = line.trimLeft();

      if (activeFenceCharacter != null) {
        if (_isClosingFence(
          leftTrimmedLine,
          character: activeFenceCharacter,
          minimumLength: activeFenceLength,
        )) {
          activeFenceCharacter = null;
          activeFenceLength = 0;
        }
      } else {
        final RegExpMatch? openingFence = _openingFencePattern.firstMatch(
          leftTrimmedLine,
        );

        if (openingFence != null) {
          final String fence = openingFence.group(1)!;
          activeFenceCharacter = fence[0];
          activeFenceLength = fence.length;
        } else {
          final RegExpMatch? headingMatch = _headingPattern.firstMatch(
            line.trim(),
          );

          if (headingMatch != null) {
            final int headingLevel = headingMatch.group(1)!.length;
            final String title = headingMatch.group(2)!.trim();

            while (stack.isNotEmpty &&
                stack.last.headingLevel >= headingLevel) {
              final _MutableRegistryDocumentNode completed = stack.removeLast();
              completed.close(endOffset: lineStart, endLine: lineNumber - 1);
            }

            final List<String> headingPath = <String>[
              if (stack.isNotEmpty) ...stack.last.headingPath,
              title,
            ];

            final _MutableRegistryDocumentNode node =
                _MutableRegistryDocumentNode(
                  title: title,
                  headingLevel: headingLevel,
                  headingPath: headingPath,
                  startLine: lineNumber,
                  startOffset: lineStart,
                );

            if (stack.isEmpty) {
              roots.add(node);
            } else {
              stack.last.children.add(node);
            }

            stack.add(node);
          }
        }
      }

      if (newlineOffset == -1) {
        break;
      }

      lineStart = newlineOffset + 1;
      lineNumber += 1;
    }

    while (stack.isNotEmpty) {
      final _MutableRegistryDocumentNode completed = stack.removeLast();
      completed.close(endOffset: source.length, endLine: lineCount);
    }

    return List<RegistryDocumentNode>.unmodifiable(
      roots.map(
        (_MutableRegistryDocumentNode node) => node.toImmutable(source),
      ),
    );
  }

  bool _isClosingFence(
    String line, {
    required String character,
    required int minimumLength,
  }) {
    int fenceLength = 0;

    while (fenceLength < line.length && line[fenceLength] == character) {
      fenceLength += 1;
    }

    if (fenceLength < minimumLength) {
      return false;
    }

    return line.substring(fenceLength).trim().isEmpty;
  }
}

final class _MutableRegistryDocumentNode {
  _MutableRegistryDocumentNode({
    required this.title,
    required this.headingLevel,
    required this.headingPath,
    required this.startLine,
    required this.startOffset,
  });

  final String title;
  final int headingLevel;
  final List<String> headingPath;
  final int startLine;
  final int startOffset;
  final List<_MutableRegistryDocumentNode> children =
      <_MutableRegistryDocumentNode>[];

  int? endLine;
  int? endOffset;

  void close({required int endOffset, required int endLine}) {
    this.endOffset = endOffset;
    this.endLine = endLine;
  }

  RegistryDocumentNode toImmutable(String source) {
    final int? resolvedEndOffset = endOffset;
    final int? resolvedEndLine = endLine;

    if (resolvedEndOffset == null || resolvedEndLine == null) {
      throw StateError('Registry document node "$title" was not closed.');
    }

    return RegistryDocumentNode(
      title: title,
      headingLevel: headingLevel,
      headingPath: headingPath,
      startLine: startLine,
      endLine: resolvedEndLine,
      sourceText: source.substring(startOffset, resolvedEndOffset),
      children: children.map(
        (_MutableRegistryDocumentNode child) => child.toImmutable(source),
      ),
    );
  }
}
