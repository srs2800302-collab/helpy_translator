import 'package:equatable/equatable.dart';

final class CanonicalOrderedBlockItem extends Equatable {
  factory CanonicalOrderedBlockItem({
    required int approvedOrder,
    required String text,
    required int sourceStartLine,
    required int sourceEndLine,
  }) {
    final String normalizedText = text.trim();

    if (approvedOrder < 1) {
      throw ArgumentError.value(
        approvedOrder,
        'approvedOrder',
        'Canonical ordered block item order must be positive.',
      );
    }

    if (normalizedText.isEmpty) {
      throw ArgumentError.value(
        text,
        'text',
        'Canonical ordered block item text must not be empty.',
      );
    }

    if (sourceStartLine < 1) {
      throw ArgumentError.value(
        sourceStartLine,
        'sourceStartLine',
        'Canonical ordered block item source start line must be positive.',
      );
    }

    if (sourceEndLine < sourceStartLine) {
      throw ArgumentError.value(
        sourceEndLine,
        'sourceEndLine',
        'Canonical ordered block item source end line must not precede '
            'its start line.',
      );
    }

    return CanonicalOrderedBlockItem._(
      approvedOrder: approvedOrder,
      text: normalizedText,
      sourceStartLine: sourceStartLine,
      sourceEndLine: sourceEndLine,
    );
  }

  const CanonicalOrderedBlockItem._({
    required this.approvedOrder,
    required this.text,
    required this.sourceStartLine,
    required this.sourceEndLine,
  });

  final int approvedOrder;
  final String text;
  final int sourceStartLine;
  final int sourceEndLine;

  @override
  List<Object?> get props => <Object?>[
    approvedOrder,
    text,
    sourceStartLine,
    sourceEndLine,
  ];
}
