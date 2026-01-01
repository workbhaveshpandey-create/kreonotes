import 'package:equatable/equatable.dart';
import '../../domain/page_model.dart';
import '../../domain/block_model.dart';

/// Pages Events
abstract class PagesEvent extends Equatable {
  const PagesEvent();

  @override
  List<Object?> get props => [];
}

/// Load all pages for user
class PagesLoadRequested extends PagesEvent {
  final String userId;
  const PagesLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Create a new page
class PageCreateRequested extends PagesEvent {
  final String userId;
  final String? title;
  final String? icon;
  final List<BlockModel>? initialBlocks;
  const PageCreateRequested(
    this.userId, {
    this.title,
    this.icon,
    this.initialBlocks,
  });

  @override
  List<Object?> get props => [userId, title, icon, initialBlocks];
}

/// Update page from stream
class PagesUpdatedFromStream extends PagesEvent {
  final List<PageModel> pages;
  const PagesUpdatedFromStream(this.pages);

  @override
  List<Object?> get props => [pages];
}

/// Select a page for editing
class PageSelected extends PagesEvent {
  final PageModel page;
  const PageSelected(this.page);

  @override
  List<Object?> get props => [page];
}

/// Deselect/Close currently selected page
class PageSelectionCleared extends PagesEvent {
  const PageSelectionCleared();
}

/// Update page title
class PageTitleUpdated extends PagesEvent {
  final String pageId;
  final String title;
  const PageTitleUpdated(this.pageId, this.title);

  @override
  List<Object?> get props => [pageId, title];
}

/// Update page icon
class PageIconUpdated extends PagesEvent {
  final String pageId;
  final String icon;
  const PageIconUpdated(this.pageId, this.icon);

  @override
  List<Object?> get props => [pageId, icon];
}

/// Update page blocks
class PageBlocksUpdated extends PagesEvent {
  final String pageId;
  final List<BlockModel> blocks;
  const PageBlocksUpdated(this.pageId, this.blocks);

  @override
  List<Object?> get props => [pageId, blocks];
}

/// Toggle favorite status
class PageFavoriteToggled extends PagesEvent {
  final String pageId;
  final bool isFavorite;
  const PageFavoriteToggled(this.pageId, this.isFavorite);

  @override
  List<Object?> get props => [pageId, isFavorite];
}

/// Archive a page
class PageArchived extends PagesEvent {
  final String pageId;
  const PageArchived(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

/// Update the entire page (title, blocks, etc.)
class UpdatePageEvent extends PagesEvent {
  final PageModel page;
  const UpdatePageEvent(this.page);

  @override
  List<Object?> get props => [page];
}

/// Delete a page permanently
class PageDeleted extends PagesEvent {
  final String pageId;
  const PageDeleted(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

/// Search pages
class PagesSearchRequested extends PagesEvent {
  final String query;
  const PagesSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

/// Clear search
class PagesSearchCleared extends PagesEvent {
  const PagesSearchCleared();
}
