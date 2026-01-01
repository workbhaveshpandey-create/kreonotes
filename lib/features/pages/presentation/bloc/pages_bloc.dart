import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/page_repository.dart';
import '../../domain/page_model.dart';
import 'pages_event.dart';
import 'pages_state.dart';

/// Pages BLoC for managing notes state
class PagesBloc extends Bloc<PagesEvent, PagesState> {
  final PageRepository _pageRepository;
  String? _currentUserId;
  StreamSubscription? _pagesSubscription;

  PagesBloc({required PageRepository pageRepository})
    : _pageRepository = pageRepository,
      super(const PagesInitial()) {
    on<PagesLoadRequested>(_onLoadRequested);
    on<PagesUpdatedFromStream>(_onUpdatedFromStream);
    on<PageCreateRequested>(_onCreateRequested);
    on<PageSelected>(_onPageSelected);
    on<PageSelectionCleared>(_onPageSelectionCleared);
    on<PageTitleUpdated>(_onTitleUpdated);
    on<PageIconUpdated>(_onIconUpdated);
    on<PageBlocksUpdated>(_onBlocksUpdated);
    on<PageFavoriteToggled>(_onFavoriteToggled);
    on<PageArchived>(_onArchived);
    on<PageDeleted>(_onDeleted);
    on<UpdatePageEvent>(_onUpdatePage);
    on<PagesSearchRequested>(_onSearchRequested);
    on<PagesSearchCleared>(_onSearchCleared);
  }

  @override
  Future<void> close() {
    _pagesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    PagesLoadRequested event,
    Emitter<PagesState> emit,
  ) async {
    emit(const PagesLoading());
    _currentUserId = event.userId;

    try {
      // Cancel existing subscription
      await _pagesSubscription?.cancel();

      // Get initial pages
      final pages = await _pageRepository.getPages(event.userId);
      final favorites = pages.where((p) => p.isFavorite).toList();

      emit(PagesLoaded(pages: pages, favoritePages: favorites));

      // Subscribe to real-time updates
      _pagesSubscription = _pageRepository.getPagesStream(event.userId).listen((
        pages,
      ) {
        add(PagesUpdatedFromStream(pages));
      });
    } catch (e) {
      emit(PagesError('Failed to load pages: ${e.toString()}'));
    }
  }

  void _onUpdatedFromStream(
    PagesUpdatedFromStream event,
    Emitter<PagesState> emit,
  ) {
    final currentState = state;
    if (currentState is PagesLoaded) {
      final favorites = event.pages.where((p) => p.isFavorite).toList();

      // Update selected page if it exists in the new list
      PageModel? updatedSelectedPage;
      if (currentState.selectedPage != null) {
        updatedSelectedPage = event.pages.firstWhere(
          (p) => p.id == currentState.selectedPage!.id,
          orElse: () => currentState.selectedPage!,
        );
      }

      emit(
        currentState.copyWith(
          pages: event.pages,
          favoritePages: favorites,
          selectedPage: updatedSelectedPage,
        ),
      );
    }
  }

  Future<void> _onCreateRequested(
    PageCreateRequested event,
    Emitter<PagesState> emit,
  ) async {
    try {
      final page = await _pageRepository.createPage(
        userId: event.userId,
        title: event.title ?? 'Untitled',
        icon: event.icon ?? '📄',
      );

      if (event.initialBlocks != null && event.initialBlocks!.isNotEmpty) {
        await _pageRepository.updatePageBlocks(page.id, event.initialBlocks!);
      }

      // Re-fetch or just update state?
      // Since repository returns the initial page, we need to update it with blocks before emitting.
      final fullPage = page.copyWith(
        blocks: event.initialBlocks ?? page.blocks,
      );

      final currentState = state;
      if (currentState is PagesLoaded) {
        emit(currentState.copyWith(selectedPage: fullPage));
      }
    } catch (e) {
      print('Error creating page: $e');
    }
  }

  void _onPageSelected(PageSelected event, Emitter<PagesState> emit) {
    final currentState = state;
    if (currentState is PagesLoaded) {
      emit(currentState.copyWith(selectedPage: event.page));
    }
  }

  void _onPageSelectionCleared(
    PageSelectionCleared event,
    Emitter<PagesState> emit,
  ) {
    final currentState = state;
    if (currentState is PagesLoaded) {
      emit(currentState.copyWith(clearSelectedPage: true));
    }
  }

  Future<void> _onTitleUpdated(
    PageTitleUpdated event,
    Emitter<PagesState> emit,
  ) async {
    try {
      await _pageRepository.updatePageTitle(event.pageId, event.title);
    } catch (e) {
      print('Error updating title: $e');
    }
  }

  Future<void> _onIconUpdated(
    PageIconUpdated event,
    Emitter<PagesState> emit,
  ) async {
    try {
      await _pageRepository.updatePageIcon(event.pageId, event.icon);
    } catch (e) {
      print('Error updating icon: $e');
    }
  }

  Future<void> _onBlocksUpdated(
    PageBlocksUpdated event,
    Emitter<PagesState> emit,
  ) async {
    try {
      await _pageRepository.updatePageBlocks(event.pageId, event.blocks);
    } catch (e) {
      print('Error updating blocks: $e');
    }
  }

  Future<void> _onFavoriteToggled(
    PageFavoriteToggled event,
    Emitter<PagesState> emit,
  ) async {
    try {
      await _pageRepository.toggleFavorite(event.pageId, event.isFavorite);
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  Future<void> _onArchived(PageArchived event, Emitter<PagesState> emit) async {
    try {
      await _pageRepository.archivePage(event.pageId);

      final currentState = state;
      if (currentState is PagesLoaded &&
          currentState.selectedPage?.id == event.pageId) {
        emit(currentState.copyWith(clearSelectedPage: true));
      }
    } catch (e) {
      print('Error archiving page: $e');
    }
  }

  Future<void> _onDeleted(PageDeleted event, Emitter<PagesState> emit) async {
    try {
      await _pageRepository.deletePage(event.pageId);

      final currentState = state;
      if (currentState is PagesLoaded &&
          currentState.selectedPage?.id == event.pageId) {
        emit(currentState.copyWith(clearSelectedPage: true));
      }
    } catch (e) {
      print('Error deleting page: $e');
    }
  }

  Future<void> _onUpdatePage(
    UpdatePageEvent event,
    Emitter<PagesState> emit,
  ) async {
    try {
      await _pageRepository.updatePage(event.page);
    } catch (e) {
      print('Error updating page: $e');
    }
  }

  Future<void> _onSearchRequested(
    PagesSearchRequested event,
    Emitter<PagesState> emit,
  ) async {
    final currentState = state;
    if (currentState is PagesLoaded && _currentUserId != null) {
      try {
        final results = await _pageRepository.searchPages(
          _currentUserId!,
          event.query,
        );
        emit(
          currentState.copyWith(
            searchQuery: event.query,
            searchResults: results,
          ),
        );
      } catch (e) {
        print('Error searching: $e');
      }
    }
  }

  void _onSearchCleared(PagesSearchCleared event, Emitter<PagesState> emit) {
    final currentState = state;
    if (currentState is PagesLoaded) {
      emit(currentState.copyWith(clearSearch: true));
    }
  }
}
