import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/page_model.dart';
import '../domain/block_model.dart';

/// Repository for page CRUD operations in Firestore
class PageRepository {
  final FirebaseFirestore _firestore;

  PageRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get collection reference
  CollectionReference<Map<String, dynamic>> get _pagesCollection =>
      _firestore.collection('pages');

  /// Create a new page
  Future<PageModel> createPage({
    required String userId,
    String title = 'Untitled',
    String icon = '📄',
  }) async {
    final now = DateTime.now();
    final page = PageModel(
      id: '',
      userId: userId,
      title: title,
      icon: icon,
      blocks: [BlockModel.text('block_1')],
      createdAt: now,
      updatedAt: now,
    );

    final docRef = await _pagesCollection.add(page.toFirestore());
    return page.copyWith(id: docRef.id);
  }

  /// Get all pages for a user
  Future<List<PageModel>> getPages(String userId) async {
    final snapshot = await _pagesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => PageModel.fromFirestore(doc)).toList();
  }

  /// Get pages stream for real-time updates
  Stream<List<PageModel>> getPagesStream(String userId) {
    return _pagesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PageModel.fromFirestore(doc)).toList(),
        );
  }

  /// Get favorite pages
  Stream<List<PageModel>> getFavoritePagesStream(String userId) {
    return _pagesCollection
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .where('isArchived', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PageModel.fromFirestore(doc)).toList(),
        );
  }

  /// Get a single page by ID
  Future<PageModel?> getPage(String pageId) async {
    final doc = await _pagesCollection.doc(pageId).get();
    if (!doc.exists) return null;
    return PageModel.fromFirestore(doc);
  }

  /// Get page stream for real-time updates
  Stream<PageModel?> getPageStream(String pageId) {
    return _pagesCollection.doc(pageId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PageModel.fromFirestore(doc);
    });
  }

  /// Update a page
  Future<void> updatePage(PageModel page) async {
    await _pagesCollection.doc(page.id).update({
      ...page.toFirestore(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update page title
  Future<void> updatePageTitle(String pageId, String title) async {
    await _pagesCollection.doc(pageId).update({
      'title': title,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update page icon
  Future<void> updatePageIcon(String pageId, String icon) async {
    await _pagesCollection.doc(pageId).update({
      'icon': icon,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update page blocks
  Future<void> updatePageBlocks(String pageId, List<BlockModel> blocks) async {
    await _pagesCollection.doc(pageId).update({
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String pageId, bool isFavorite) async {
    await _pagesCollection.doc(pageId).update({
      'isFavorite': isFavorite,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Archive a page (soft delete)
  Future<void> archivePage(String pageId) async {
    await _pagesCollection.doc(pageId).update({
      'isArchived': true,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Restore an archived page
  Future<void> restorePage(String pageId) async {
    await _pagesCollection.doc(pageId).update({
      'isArchived': false,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a page permanently
  Future<void> deletePage(String pageId) async {
    await _pagesCollection.doc(pageId).delete();
  }

  /// Search pages by title
  Future<List<PageModel>> searchPages(String userId, String query) async {
    // Firestore doesn't support full-text search, so we fetch all and filter
    final pages = await getPages(userId);
    final lowerQuery = query.toLowerCase();
    return pages.where((page) {
      return page.title.toLowerCase().contains(lowerQuery) ||
          page.blocks.any(
            (block) => block.content.toLowerCase().contains(lowerQuery),
          );
    }).toList();
  }
}
