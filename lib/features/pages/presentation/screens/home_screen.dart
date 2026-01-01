import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/page_model.dart';
import '../../domain/block_model.dart'; // Export BlockType
import '../bloc/pages_bloc.dart';
import '../bloc/pages_state.dart';
import '../bloc/pages_event.dart';
import 'page_editor_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../settings/presentation/views/settings_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import '../../data/ai_service.dart';
import 'dart:ui'; // For BackboneFilter (ImageFilter)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showArchived = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isProcessingAI = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagesBloc, PagesState>(
      builder: (context, state) {
        if (state is PagesLoaded && state.selectedPage != null) {
          // Auto-open with Fade Transition as requested
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) return;
              context.read<PagesBloc>().add(const PageSelectionCleared());
            },
            child: Navigator(
              onGenerateRoute: (_) => PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    PageEditorScreen(page: state.selectedPage!),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey, // Assign Key
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: _buildDrawer(context),
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Background Gradient or texture?
                // Let's keep it clean black for high contrast premium feel.
                _buildBody(context, state),
                if (_isProcessingAI)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withOpacity(0.85),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (index) {
                                  return Container(
                                        width: 6,
                                        height: 32,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purpleAccent
                                              .withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      )
                                      .animate(
                                        onPlay: (c) => c.repeat(reverse: true),
                                      )
                                      .scaleY(
                                        begin: 0.2,
                                        end: 1.5,
                                        curve: Curves.easeInOut,
                                        duration: 600.ms,
                                        delay: (index * 100).ms,
                                      );
                                }),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                    "Creating your masterpiece...",
                                    style: AppTextStyles.titleMedium(
                                      color: Colors.white,
                                    ).copyWith(letterSpacing: 1.2),
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .shimmer(
                                    duration: 1500.ms,
                                    color: Colors.purpleAccent,
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI Create FAB
              if (!_showArchived)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FloatingActionButton(
                    heroTag: 'assistant_fab',
                    onPressed: _isListening ? _stopListening : _startListening,
                    backgroundColor: _isListening
                        ? Colors.redAccent
                        : Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.auto_awesome,
                      color: Colors.white,
                    ),
                  ),
                ),
              FloatingActionButton(
                heroTag: 'add_fab',
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  final userId = (authState is AuthAuthenticated)
                      ? authState.user.uid
                      : 'local';
                  context.read<PagesBloc>().add(
                    PageCreateRequested(userId, title: '', icon: '📄'),
                  );
                },
                backgroundColor: Theme.of(
                  context,
                ).floatingActionButtonTheme.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(
                    context,
                  ).floatingActionButtonTheme.foregroundColor,
                  size: 32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Text(
                      "K",
                      style: AppTextStyles.headlineSmall(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kreo Notes",
                        style: AppTextStyles.titleLarge(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Premium Workspace",
                        style: AppTextStyles.bodySmall(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Navigation Items
          _buildDrawerItem(
            context,
            icon: Icons.lightbulb_outline,
            label: 'Notes',
            isSelected: !_showArchived,
            onTap: () {
              setState(() => _showArchived = false);
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.archive_outlined,
            label: 'Archive',
            isSelected: _showArchived,
            onTap: () {
              setState(() => _showArchived = true);
              Navigator.pop(context);
            },
          ),
          const Divider(height: 1, thickness: 1), // Separator
          _buildDrawerItem(
            context,
            icon: Icons.settings_outlined,
            label: 'Settings',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).iconTheme.color?.withOpacity(0.7),
        ),
        title: Text(
          label,
          style:
              AppTextStyles.bodyMedium(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ).copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PagesState state) {
    if (state is PagesLoaded) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [_buildSliverAppBar(state), _buildPagesList(context, state)],
      );
    } else if (state is PagesInitial) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is PagesError) {
      return Center(
        child: Text(state.message, style: const TextStyle(color: Colors.red)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSliverAppBar(PagesLoaded state) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 70, // Slightly taller
      flexibleSpace: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(), // Fix
              ),
              Expanded(
                child: TextField(
                  style: AppTextStyles.bodyMedium(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: _showArchived
                        ? 'Search archive'
                        : 'Search your notes',
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (query) {
                    context.read<PagesBloc>().add(PagesSearchRequested(query));
                  },
                ),
              ),
              if (state.searchQuery?.isNotEmpty ?? false)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () =>
                      context.read<PagesBloc>().add(const PagesSearchCleared()),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24,
                  ),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black,
                    child: Text(
                      'B',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagesList(BuildContext context, PagesLoaded state) {
    List<PageModel> pagesToShow = [];
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      pagesToShow = (state.searchResults ?? [])
          .where((p) => p.isArchived == _showArchived)
          .toList();
    } else {
      pagesToShow = state.pages
          .where((p) => p.isArchived == _showArchived)
          .toList();
    }

    pagesToShow.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    if (pagesToShow.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showArchived ? Icons.archive_outlined : Icons.note_outlined,
                size: 64,
                color: Colors.white24,
              ),
              const SizedBox(height: 16),
              Text(
                _showArchived
                    ? "No archived notes"
                    : "Your notes will appear here",
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childCount: pagesToShow.length,
        itemBuilder: (context, index) {
          final page = pagesToShow[index];
          return _buildNoteCard(context, page);
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, PageModel page) {
    // Determine card styling based on pinned status or color
    // We want a unified "Glass/Dark" look.
    // If user set a color, we tint the glass.

    final baseColor = _getColor(page.color);
    // If default, use dark glass. If colored, use that color but dimmed/modern.
    // Actually user wants "Redesigned".
    // Let's use darker, richer colors.

    return GestureDetector(
      onTap: () {
        context.read<PagesBloc>().add(PageSelected(page));
      },
      child:
          Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (page.color == null || page.color == 'default')
                      ? Theme.of(context).cardColor
                      : baseColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(
                    24,
                  ), // More rounded (Squircle-ish)
                  border: Border.all(
                    color: (page.color == null || page.color == 'default')
                        ? Theme.of(context).dividerColor
                        : baseColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: page.title.isNotEmpty
                              ? Text(
                                  page.title,
                                  style:
                                      AppTextStyles.titleMedium(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.color,
                                      ).copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                )
                              : const SizedBox(), // Placeholder logic if needed
                        ),
                        if (page.isFavorite)
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                    if (page.title.isNotEmpty) const SizedBox(height: 12),
                    if (page.blocks.isNotEmpty)
                      Text(
                        _getPreviewText(page),
                        style: AppTextStyles.bodySmall(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ).copyWith(height: 1.5, fontSize: 14),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // Time or minimal footer?
                    const SizedBox(height: 8),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
    );
  }

  String _getPreviewText(PageModel page) {
    if (page.blocks.isEmpty) return 'Empty note';
    final buffer = StringBuffer();
    for (var i = 0; i < page.blocks.length && i < 3; i++) {
      final b = page.blocks[i];
      if (b.type == BlockType.text ||
          b.type == BlockType.todo ||
          b.type == BlockType.callout) {
        buffer.write(b.content);
        buffer.write(' ');
      }
    }
    String preview = buffer.toString().trim();
    if (preview.isEmpty) return 'Image / Media';
    return preview;
  }

  Color _getColor(String? colorName) {
    switch (colorName) {
      case 'red':
        return AppColors.noteRed;
      case 'orange':
        return AppColors.noteOrange;
      case 'yellow':
        return AppColors.noteYellow;
      case 'green':
        return AppColors.noteGreen;
      case 'cyan':
        return AppColors.noteCyan;
      case 'blue':
        return AppColors.noteBlue;
      case 'purple':
        return AppColors.notePurple;
      case 'pink':
        return AppColors.notePink;
      case 'brown':
        return AppColors.noteBrown;
      case 'grey':
        return AppColors.noteGrey;
      default:
        return AppColors.noteDefault;
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (_) => setState(() => _isListening = false),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            _processVoiceCommand(val.recognizedWords);
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _processVoiceCommand(String text) async {
    if (text.isEmpty) return;
    setState(() {
      _isListening = false;
      _isProcessingAI = true;
    });

    try {
      // 1. Generate Content
      final content = await AiService().generateNoteContent(text);

      // 2. Parse Content (Simple Markdown Parsing)
      String title = 'AI Note';
      String body = content;

      final lines = content.split('\n');
      if (lines.isNotEmpty && lines.first.startsWith('#')) {
        title = lines.first.replaceAll('#', '').trim();
        body = lines.sublist(1).join('\n').trim();
      }

      // 3. Create Blocks
      final List<BlockModel> blocks = [];

      // Image Block First (using title or prompt)
      final imagePrompt = title.isNotEmpty ? title : text;
      final imageUrl = AiService().generateImageUrl(imagePrompt);
      blocks.add(
        BlockModel(
          id: const Uuid().v4(),
          type: BlockType.image,
          content: imageUrl,
        ),
      );

      if (body.isNotEmpty) {
        final bodyLines = body.split('\n');
        for (var line in bodyLines) {
          line = line.trim();
          if (line.isEmpty) continue;

          if (line.startsWith('- [ ]')) {
            blocks.add(
              BlockModel(
                id: const Uuid().v4(),
                type: BlockType.todo,
                content: line.replaceFirst(RegExp(r'^- \[[ x]?\] '), '').trim(),
                isChecked: line.contains('[x]'),
              ),
            );
          } else if (line.startsWith('- ')) {
            blocks.add(
              BlockModel(
                id: const Uuid().v4(),
                type: BlockType.bullet,
                content: line.substring(2).trim(),
              ),
            );
          } else {
            blocks.add(
              BlockModel(
                id: const Uuid().v4(),
                type: BlockType.text,
                content: line,
              ),
            );
          }
        }
      }

      // 4. Create Page
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        final userId = (authState is AuthAuthenticated)
            ? authState.user.uid
            : 'local';

        context.read<PagesBloc>().add(
          PageCreateRequested(
            userId,
            title: title,
            icon: '🤖',
            initialBlocks: blocks,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }
}
