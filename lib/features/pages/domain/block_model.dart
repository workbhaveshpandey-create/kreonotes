import 'package:equatable/equatable.dart';
import 'style_span.dart';

enum BlockType {
  text,
  heading,
  todo,
  bullet,
  quote,
  code,
  divider,
  callout,
  image,
}

class BlockModel extends Equatable {
  final String id;
  final BlockType type;
  final String content;
  final int? level; // For headings
  final bool? isChecked; // For todos
  final Map<String, dynamic>? metadata; // For styling, language, etc.
  final List<StyleSpan> spans; // For inline formatting

  const BlockModel({
    required this.id,
    required this.type,
    required this.content,
    this.level,
    this.isChecked,
    this.metadata,
    this.spans = const [],
  });

  BlockModel copyWith({
    String? id,
    BlockType? type,
    String? content,
    int? level,
    bool? isChecked,
    Map<String, dynamic>? metadata,
    List<StyleSpan>? spans,
  }) {
    return BlockModel(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      level: level ?? this.level,
      isChecked: isChecked ?? this.isChecked,
      metadata: metadata ?? this.metadata,
      spans: spans ?? this.spans,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'level': level,
      'isChecked': isChecked,
      'metadata': metadata,
      'spans': spans.map((s) => s.toMap()).toList(),
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      id: map['id'] as String? ?? '',
      type: BlockType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BlockType.text,
      ),
      content: map['content'] as String? ?? '',
      level: map['level'] as int?,
      isChecked: map['isChecked'] as bool?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      spans:
          (map['spans'] as List<dynamic>?)
              ?.map((e) => StyleSpan.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convenience factory for text block
  factory BlockModel.text(String id, {String content = ''}) {
    return BlockModel(id: id, type: BlockType.text, content: content);
  }

  @override
  List<Object?> get props => [
    id,
    type,
    content,
    level,
    isChecked,
    metadata,
    spans,
  ];
}
