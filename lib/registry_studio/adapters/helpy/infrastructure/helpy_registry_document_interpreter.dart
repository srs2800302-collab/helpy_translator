import 'dart:convert';

import '../../../core/domain/value_objects/registry_path.dart';

final class HelpyRegistryDocumentNode {
  const HelpyRegistryDocumentNode._({
    required this.headingLevel,
    required this.path,
    required this.startLine,
    required this.endLine,
    required this.content,
    required this.children,
  });

  final int headingLevel;
  final RegistryPath path;
  final int startLine;
  final int endLine;
  final String content;
  final List<HelpyRegistryDocumentNode> children;
}

final class HelpyRegistryDocumentInterpreter {
  const HelpyRegistryDocumentInterpreter();

  List<HelpyRegistryDocumentNode> interpret(String sourceContent) {
    if (sourceContent.trim().isEmpty) {
      throw ArgumentError.value(
        sourceContent,
        'sourceContent',
        'Helpy Registry source content must not be empty.',
      );
    }

    final List<String> lines = const LineSplitter().convert(sourceContent);
    final RegExp fencedCodePattern = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
    final RegExp headingPattern = RegExp(r'^ {0,3}(#{1,6})(?:[ \t]+|$)(.*)$');
    final RegExp closingHeadingMarksPattern = RegExp(r'[ \t]+#+[ \t]*$');

    final List<({int headingLevel, RegistryPath path, int startLine})>
    headings = <({int headingLevel, RegistryPath path, int startLine})>[];

    final List<({int headingLevel, String heading})> activeHeadingPath =
        <({int headingLevel, String heading})>[];

    final Set<RegistryPath> discoveredPaths = <RegistryPath>{};

    String? activeFenceMarker;
    int activeFenceLength = 0;

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex += 1) {
      final String line = lines[lineIndex];
      final int lineNumber = lineIndex + 1;
      final RegExpMatch? fencedCodeMatch = fencedCodePattern.firstMatch(line);

      if (fencedCodeMatch != null) {
        if (headings.isEmpty && activeFenceMarker == null) {
          throw FormatException(
            'Helpy Registry contains nonblank source content before its first '
            'structural heading at line $lineNumber.',
          );
        }

        final String marker = fencedCodeMatch.group(1)!;
        final String trailingContent = fencedCodeMatch.group(2)!;
        final String markerCharacter = marker[0];

        if (activeFenceMarker == null) {
          activeFenceMarker = markerCharacter;
          activeFenceLength = marker.length;
          continue;
        }

        if (markerCharacter == activeFenceMarker &&
            marker.length >= activeFenceLength &&
            trailingContent.trim().isEmpty) {
          activeFenceMarker = null;
          activeFenceLength = 0;
        }

        continue;
      }

      if (activeFenceMarker != null) {
        continue;
      }

      final RegExpMatch? headingMatch = headingPattern.firstMatch(line);

      if (headingMatch == null) {
        if (headings.isEmpty && line.trim().isNotEmpty) {
          throw FormatException(
            'Helpy Registry contains nonblank source content before its first '
            'structural heading at line $lineNumber.',
          );
        }

        continue;
      }

      final int headingLevel = headingMatch.group(1)!.length;
      final String heading = headingMatch
          .group(2)!
          .replaceFirst(closingHeadingMarksPattern, '')
          .trim();

      if (heading.isEmpty) {
        throw FormatException(
          'Helpy Registry heading at line $lineNumber must not be empty.',
        );
      }

      while (activeHeadingPath.isNotEmpty &&
          activeHeadingPath.last.headingLevel >= headingLevel) {
        activeHeadingPath.removeLast();
      }

      if (activeHeadingPath.isNotEmpty &&
          headingLevel > activeHeadingPath.last.headingLevel + 1) {
        throw FormatException(
          'Helpy Registry heading at line $lineNumber skips a structural '
          'heading level.',
        );
      }

      final RegistryPath path = RegistryPath(<String>[
        ...activeHeadingPath.map(
          (({int headingLevel, String heading}) item) => item.heading,
        ),
        heading,
      ]);

      if (!discoveredPaths.add(path)) {
        throw FormatException(
          'Helpy Registry contains duplicate heading path at line '
          '$lineNumber: ${path.segments.join(' → ')}.',
        );
      }

      headings.add((
        headingLevel: headingLevel,
        path: path,
        startLine: lineNumber,
      ));

      activeHeadingPath.add((headingLevel: headingLevel, heading: heading));
    }

    if (activeFenceMarker != null) {
      throw const FormatException(
        'Helpy Registry contains an unclosed fenced code block.',
      );
    }

    if (headings.isEmpty) {
      throw const FormatException(
        'Helpy Registry must contain at least one Markdown heading.',
      );
    }

    final List<({int headingLevel, HelpyRegistryDocumentNode node})>
    completedNodes = <({int headingLevel, HelpyRegistryDocumentNode node})>[];

    for (int index = headings.length - 1; index >= 0; index -= 1) {
      final ({int headingLevel, RegistryPath path, int startLine}) heading =
          headings[index];

      final List<HelpyRegistryDocumentNode> children =
          <HelpyRegistryDocumentNode>[];

      while (completedNodes.isNotEmpty &&
          completedNodes.last.headingLevel > heading.headingLevel) {
        children.add(completedNodes.removeLast().node);
      }

      final int endLine = completedNodes.isEmpty
          ? lines.length
          : completedNodes.last.node.startLine - 1;

      final int directContentEndLine = children.isEmpty
          ? endLine
          : children.first.startLine - 1;

      String directContent = '';

      if (directContentEndLine > heading.startLine) {
        final List<String> directContentLines = lines.sublist(
          heading.startLine,
          directContentEndLine,
        );

        int firstContentLine = 0;
        int lastContentLine = directContentLines.length;

        while (firstContentLine < lastContentLine &&
            directContentLines[firstContentLine].trim().isEmpty) {
          firstContentLine += 1;
        }

        while (lastContentLine > firstContentLine &&
            directContentLines[lastContentLine - 1].trim().isEmpty) {
          lastContentLine -= 1;
        }

        if (firstContentLine < lastContentLine) {
          directContent = directContentLines
              .sublist(firstContentLine, lastContentLine)
              .join('\n');
        }
      }

      completedNodes.add((
        headingLevel: heading.headingLevel,
        node: HelpyRegistryDocumentNode._(
          headingLevel: heading.headingLevel,
          path: heading.path,
          startLine: heading.startLine,
          endLine: endLine,
          content: directContent,
          children: List<HelpyRegistryDocumentNode>.unmodifiable(children),
        ),
      ));
    }

    final List<HelpyRegistryDocumentNode> roots = <HelpyRegistryDocumentNode>[];

    while (completedNodes.isNotEmpty) {
      roots.add(completedNodes.removeLast().node);
    }

    return List<HelpyRegistryDocumentNode>.unmodifiable(roots);
  }
}
