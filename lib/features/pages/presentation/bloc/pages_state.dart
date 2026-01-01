import 'package:equatable/equatable.dart';
import '../../domain/page_model.dart';

/// Pages States
abstract class PagesState extends Equatable {
  const PagesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PagesInitial extends PagesState {
  const PagesInitial();
}

/// Loading pages
class PagesLoading extends PagesState {
  const PagesLoading();
}

/// Pages loaded successfully
class PagesLoaded extends PagesState {
  final List<PageModel> pages;
  final List<PageModel> favoritePages;
  final PageModel? selectedPage;
  final String? searchQuery;
  final List<PageModel>? searchResults;

  const PagesLoaded({
    required this.pages,
    this.favoritePages = const [],
    this.selectedPage,
    this.searchQuery,
    this.searchResults,
  });

  PagesLoaded copyWith({
    List<PageModel>? pages,
    List<PageModel>? favoritePages,
    PageModel? selectedPage,
    String? searchQuery,
    List<PageModel>? searchResults,
    bool clearSelectedPage = false,
    bool clearSearch = false,
  }) {
    return PagesLoaded(
      pages: pages ?? this.pages,
      favoritePages: favoritePages ?? this.favoritePages,
      selectedPage: clearSelectedPage
          ? null
          : (selectedPage ?? this.selectedPage),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      searchResults: clearSearch ? null : (searchResults ?? this.searchResults),
    );
  }

  @override
  List<Object?> get props => [
    pages,
    favoritePages,
    selectedPage,
    searchQuery,
    searchResults,
  ];
}

/// Error loading pages
class PagesError extends PagesState {
  final String message;
  const PagesError(this.message);

  @override
  List<Object?> get props => [message];
}
