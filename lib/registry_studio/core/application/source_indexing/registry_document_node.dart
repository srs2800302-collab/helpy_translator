import 'package:equatable/equatable.dart';

final class RegistryDocumentNode extends Equatable {
  factory RegistryDocumentNode({
    required String title,
    required int headingLevel,
    required Iterable<String> headingPath,
    required int startLine,
    required int endLine,
    required String sourceText,
    required Iterable<RegistryDocumentNode> children,
  }) {
    final String normalizedTitle = title.trim();
    final List<String> normalizedHeadingPath = headingPath
        .map((String segment) => segment.trim())
        .toList(growable: false);
    final List<RegistryDocumentNode> normalizedChildren = children.toList(
      growable: false,
    );

    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Registry document heading title must not be empty.',
      );
    }

    if (headingLevel < 1 || headingLevel > 6) {
      throw ArgumentError.value(
        headingLevel,
        'headingLevel',
        'Registry document heading level must be between 1 and 6.',
      );
    }

    if (normalizedHeadingPath.isEmpty ||
        normalizedHeadingPath.any((String segment) => segment.isEmpty) ||
        normalizedHeadingPath.last != normalizedTitle) {
      throw ArgumentError.value(
        headingPath,
        'headingPath',
        'Registry document heading path must be non-empty and end with title.',
      );
    }

    if (startLine <= 0 || endLine < startLine) {
      throw ArgumentError(
        'Registry document source range must be positive and ordered.',
      );
    }

    if (sourceText.isEmpty) {
      throw ArgumentError.value(
        sourceText,
        'sourceText',
        'Registry document section source text must not be empty.',
      );
    }

    return RegistryDocumentNode._(
      title: normalizedTitle,
      headingLevel: headingLevel,
      headingPath: List<String>.unmodifiable(normalizedHeadingPath),
      startLine: startLine,
      endLine: endLine,
      sourceText: sourceText,
      children: List<RegistryDocumentNode>.unmodifiable(normalizedChildren),
    );
  }

  const RegistryDocumentNode._({
    required this.title,
    required this.headingLevel,
    required this.headingPath,
    required this.startLine,
    required this.endLine,
    required this.sourceText,
    required this.children,
  });

  final String title;
  final int headingLevel;
  final List<String> headingPath;
  final int startLine;
  final int endLine;
  final String sourceText;
  final List<RegistryDocumentNode> children;

  @override
  List<Object?> get props => <Object?>[
    title,
    headingLevel,
    headingPath,
    startLine,
    endLine,
    sourceText,
    children,
  ];
}
