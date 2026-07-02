import 'package:equatable/equatable.dart';

final class RegistryNode extends Equatable {
  const RegistryNode({
    required this.id,
    required this.title,
    required this.level,
    required this.lineNumber,
    required this.phrases,
    required this.children,
  });

  final String id;
  final String title;
  final int level;
  final int lineNumber;
  final List<String> phrases;
  final List<RegistryNode> children;

  RegistryNode copyWith({
    String? id,
    String? title,
    int? level,
    int? lineNumber,
    List<String>? phrases,
    List<RegistryNode>? children,
  }) {
    return RegistryNode(
      id: id ?? this.id,
      title: title ?? this.title,
      level: level ?? this.level,
      lineNumber: lineNumber ?? this.lineNumber,
      phrases: phrases ?? this.phrases,
      children: children ?? this.children,
    );
  }

  int get totalPhrases {
    return phrases.length +
        children.fold<int>(
          0,
          (int total, RegistryNode child) => total + child.totalPhrases,
        );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        level,
        lineNumber,
        phrases,
        children,
      ];
}
