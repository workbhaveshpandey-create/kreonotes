import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'block_model.dart';

/// A page/note in Kreo Notes
class PageModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String icon; // Emoji icon
  final String? coverUrl;
  final String? parentId; // For nested pages
  final String? color; // Hex string or color name
  final List<BlockModel> blocks;
  final bool isFavorite;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PageModel({
    required this.id,
    required this.userId,
    required this.title,
    this.icon = '📄',
    this.coverUrl,
    this.parentId,
    this.color,
    this.blocks = const [],
    this.isFavorite = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory PageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse blocks
    final blocksList = <BlockModel>[];
    if (data['blocks'] != null) {
      for (final block in data['blocks']) {
        blocksList.add(BlockModel.fromMap(block as Map<String, dynamic>));
      }
    }

    return PageModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Untitled',
      icon: data['icon'] ?? '📄',
      coverUrl: data['coverUrl'],
      parentId: data['parentId'],
      color: data['color'],
      blocks: blocksList,
      isFavorite: data['isFavorite'] ?? false,
      isArchived: data['isArchived'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'icon': icon,
      'coverUrl': coverUrl,
      'parentId': parentId,
      'color': color,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  PageModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? icon,
    String? coverUrl,
    String? parentId,
    String? color,
    List<BlockModel>? blocks,
    bool? isFavorite,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      coverUrl: coverUrl ?? this.coverUrl,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      blocks: blocks ?? this.blocks,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a new empty page
  factory PageModel.create({
    required String userId,
    String title = 'Untitled',
    String icon = '📄',
  }) {
    final now = DateTime.now();
    return PageModel(
      id: '',
      userId: userId,
      title: title,
      icon: icon,
      blocks: [BlockModel.text('block_1')],
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    icon,
    coverUrl,
    parentId,
    color,
    blocks,
    isFavorite,
    isArchived,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() =>
      'PageModel(id: $id, title: $title, blocks: ${blocks.length})';
}
