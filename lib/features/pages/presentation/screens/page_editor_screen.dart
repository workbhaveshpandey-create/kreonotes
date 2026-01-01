import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io'; // Added for File usage

import '../../../../app/theme/app_theme.dart';
import '../../domain/page_model.dart';
import '../../domain/block_model.dart';
import '../../domain/style_span.dart'; // Import StyleSpan
import '../bloc/pages_bloc.dart';
import '../bloc/pages_event.dart';
import '../widgets/block_widget.dart';
import '../widgets/image_block_widget.dart';
import '../widgets/formatting_toolbar.dart';
import 'drawing_screen.dart';
import '../../data/ai_service.dart';

class PageEditorScreen extends StatefulWidget {
  final PageModel page;

  const PageEditorScreen({super.key, required this.page});

  @override
  State<PageEditorScreen> createState() => _PageEditorScreenState();
}

class _PageEditorScreenState extends State<PageEditorScreen> {
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  late List<BlockModel> _blocks;
  final ScrollController _scrollController = ScrollController();

  // Color State
  String _pageColor = 'default';

  // Focus Management
  final Map<String, FocusNode> _focusNodes = {};
  String? _selectedBlockId;

  // UI Toggles
  bool _showFormatting = false;
  TextSelection? _currentSelection; // Track selection for inline formatting

  // Voice AI
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.page.title);
    _titleFocusNode = FocusNode();
    _pageColor = widget.page.color ?? 'default';

    // Hide formatting when title focused
    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        setState(() {
          _selectedBlockId = null;
          _showFormatting = false; // Auto-hide
        });
      }
    });

    _blocks = List.from(widget.page.blocks); // Local copy
    if (_blocks.isEmpty) {
      _blocks.add(BlockModel.text(const Uuid().v4()));
    }

    // Auto-select last
    if (_blocks.isNotEmpty) {
      _selectedBlockId = _blocks.last.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    _scrollController.dispose();
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // --- Helpers ---

  Color _getColor(String colorName) {
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

  FocusNode _getFocusNode(String id) {
    if (_focusNodes.containsKey(id)) {
      return _focusNodes[id]!;
    }
    final node = FocusNode();
    node.addListener(() {
      if (node.hasFocus) {
        setState(() {
          _selectedBlockId = id;
        });
      }
    });
    _focusNodes[id] = node;
    return node;
  }

  void _save() {
    context.read<PagesBloc>().add(
      UpdatePageEvent(
        widget.page.copyWith(
          title: _titleController.text,
          blocks: _blocks,
          color: _pageColor,
        ),
      ),
    );
  }

  // --- Block Operations ---

  void _addBlock(BlockType type, int index, [String content = '']) {
    final newBlock = BlockModel(
      id: const Uuid().v4(),
      type: type,
      content: content,
    );
    setState(() {
      _blocks.insert(index + 1, newBlock);
      _selectedBlockId = newBlock.id;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getFocusNode(newBlock.id).requestFocus();
    });
  }

  void _updateBlock(int index, BlockModel newBlock) {
    setState(() {
      _blocks[index] = newBlock;
    });
  }

  void _removeBlock(int index) {
    final idToRemove = _blocks[index].id;
    setState(() {
      _blocks.removeAt(index);
      _focusNodes[idToRemove]?.dispose();
      _focusNodes.remove(idToRemove);

      if (_blocks.isEmpty) {
        final newId = const Uuid().v4();
        _blocks.add(BlockModel.text(newId));
        _selectedBlockId = newId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _getFocusNode(newId).requestFocus();
        });
      } else {
        if (index > 0) {
          _selectedBlockId = _blocks[index - 1].id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _getFocusNode(_blocks[index - 1].id).requestFocus();
          });
        } else {
          _selectedBlockId = _blocks.first.id;
        }
      }
    });
  }

  void _handleEmptySpaceTap() {
    if (_blocks.isEmpty) return;
    final lastBlock = _blocks.last;
    if (lastBlock.type == BlockType.text && lastBlock.content.isEmpty) {
      _getFocusNode(lastBlock.id).requestFocus();
    } else {
      _addBlock(BlockType.text, _blocks.length - 1);
    }
  }

  // --- Styling ---

  void _setPageColor(String colorName) {
    setState(() {
      _pageColor = colorName;
    });
    Navigator.pop(context); // Close palette
    _save(); // Save immediately?
  }

  void _applyStyle(String key, dynamic value) {
    if (_selectedBlockId == null) return;
    final index = _blocks.indexWhere((b) => b.id == _selectedBlockId);
    if (index == -1) return;

    final block = _blocks[index];

    // Check if we have a selection for inline formatting
    // Check for inline style keys
    final isInlineStyle = [
      'bold',
      'italic',
      'underline',
      'color',
    ].contains(key);

    if (isInlineStyle) {
      if (_currentSelection != null && !_currentSelection!.isCollapsed) {
        // Apply span to selection
        final start = _currentSelection!.start;
        final end = _currentSelection!.end;

        StyleType type;
        String? styleValue;

        if (key == 'bold')
          type = StyleType.bold;
        else if (key == 'italic')
          type = StyleType.italic;
        else if (key == 'underline')
          type = StyleType.underline;
        else if (key == 'color') {
          type = StyleType.color;
          styleValue = value as String;
        } else
          return;

        final newSpan = StyleSpan(
          start: start,
          end: end,
          type: type,
          value: styleValue,
        );
        final updatedSpans = List<StyleSpan>.from(block.spans)..add(newSpan);
        _updateBlock(index, block.copyWith(spans: updatedSpans));
      }
      // If no selection, DO NOT apply to block metadata. Maybe handle word-at-cursor later.
      // For now, doing nothing is safer than coloring the whole block unexpectedly.
    } else {
      // Valid Block Level Styles (like checking a todo)
      final metadata = Map<String, dynamic>.from(block.metadata ?? {});
      if (value is bool && value == true) {
        metadata[key] = !(metadata[key] == true);
      } else {
        metadata[key] = value;
      }
      _updateBlock(index, block.copyWith(metadata: metadata));
    }
  }

  void _changeBlockType(BlockType type, {int? level}) {
    if (_selectedBlockId == null) return;
    final index = _blocks.indexWhere((b) => b.id == _selectedBlockId);
    if (index == -1) return;

    var newBlock = _blocks[index].copyWith(type: type);
    if (level != null) {
      newBlock = newBlock.copyWith(level: level);
    }
    _updateBlock(index, newBlock);
  }

  // --- Menus ---

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.redAccent),
              title: Text(
                'Recording',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _listen();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Take photo',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.image,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Add image',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.auto_awesome,
                color: Theme.of(
                  context,
                ).iconTheme.color, // Match theme like others
              ),
              title: Text(
                'AI Images',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _generateAIImage();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.brush,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Drawing',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DrawingScreen(),
                  ),
                );
                if (result != null && result is String) {
                  // Add image block with the returned path
                  int index = _blocks.length - 1;
                  if (_selectedBlockId != null) {
                    final idx = _blocks.indexWhere(
                      (b) => b.id == _selectedBlockId,
                    );
                    if (idx != -1) index = idx;
                  }
                  final newBlock = BlockModel(
                    id: const Uuid().v4(),
                    type: BlockType.image,
                    content: result,
                  );
                  setState(() {
                    _blocks.insert(index + 1, newBlock);
                    _selectedBlockId = newBlock.id;
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check_box_outlined,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                'Tick boxes',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _changeBlockType(BlockType.todo);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPalette() {
    final colors = [
      'default',
      'red',
      'orange',
      'yellow',
      'green',
      'cyan',
      'blue',
      'purple',
      'pink',
      'brown',
      'grey',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final c = colors[index];
            return GestureDetector(
              onTap: () => _setPageColor(c),
              child: Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: _getColor(c),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _pageColor == c
                        ? Theme.of(context).iconTheme.color!
                        : Theme.of(context).dividerColor,
                    width: _pageColor == c ? 2 : 1,
                  ),
                ),
                child: _pageColor == c
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).iconTheme.color,
                      )
                    : (c == 'default'
                          ? const Icon(
                              Icons.format_color_reset,
                              color: Colors.white38,
                              size: 20,
                            )
                          : null),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Voice & Image ---

  Future<void> _listen() async {
    // Permission check handled by initializing
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening')
            setState(() => _isListening = false);
        },
        onError: (_) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (val.finalResult) _processVoiceInput(val.recognizedWords);
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _processVoiceInput(String text) async {
    if (text.isEmpty) return;
    _addBlock(BlockType.text, _blocks.length - 1, text);
    // AI Summary
    try {
      final summary = await AiService().summarize(text);
      if (mounted) {
        setState(() {
          _blocks.add(
            BlockModel(
              id: const Uuid().v4(),
              type: BlockType.callout,
              content: "✨ $summary",
            ),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file != null) {
      int index = _blocks.length - 1;
      if (_selectedBlockId != null) {
        final idx = _blocks.indexWhere((b) => b.id == _selectedBlockId);
        if (idx != -1) index = idx;
      }
      final newBlock = BlockModel(
        id: const Uuid().v4(),
        type: BlockType.image,
        content: file.path,
      );
      setState(() {
        _blocks.insert(index + 1, newBlock);
        _selectedBlockId = newBlock.id;
      });
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        _save();
        context.read<PagesBloc>().add(const PageSelectionCleared());
      },
      child: Scaffold(
        backgroundColor: _getColor(_pageColor) == AppColors.noteDefault
            ? Theme.of(context).scaffoldBackgroundColor
            : _getColor(_pageColor),
        resizeToAvoidBottomInset: true,
        // Custom App Bar
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              _save();
              context.read<PagesBloc>().add(const PageSelectionCleared());
            },
          ),
          actions: [
            IconButton(
              icon: _isListening
                  ? const Icon(
                      Icons.mic,
                      color: Colors.redAccent,
                    ).animate(onPlay: (c) => c.repeat()).fadeIn().fadeOut()
                  : const SizedBox(),
              onPressed: _isListening ? _listen : null,
            ),
            IconButton(
              icon: Icon(
                widget.page.isFavorite
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                color: widget.page.isFavorite
                    ? Colors.blueAccent
                    : Theme.of(context).iconTheme.color?.withOpacity(0.7),
              ),
              onPressed: () {
                context.read<PagesBloc>().add(
                  PageFavoriteToggled(widget.page.id, !widget.page.isFavorite),
                );
              },
            ),
            IconButton(
              icon: Icon(
                widget.page.isArchived ? Icons.archive : Icons.archive_outlined,
                color: widget.page.isArchived
                    ? Colors.blueAccent
                    : Theme.of(context).iconTheme.color?.withOpacity(0.7),
              ),
              onPressed: () {
                context.read<PagesBloc>().add(
                  UpdatePageEvent(
                    widget.page.copyWith(isArchived: !widget.page.isArchived),
                  ),
                );
                // Also clear selection if archiving
                context.read<PagesBloc>().add(const PageSelectionCleared());
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _handleEmptySpaceTap,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      style: AppTextStyles.displaySmall(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 16),
                    // Blocks
                    ..._blocks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final block = entry.value;
                      if (block.type == BlockType.image) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FullScreenImageViewer(
                                  imagePath: block.content,
                                ),
                              ),
                            );
                          },
                          onLongPress: () {
                            setState(() => _selectedBlockId = block.id);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: _selectedBlockId == block.id
                                ? BoxDecoration(
                                    border: Border.all(
                                      color: Colors.blueAccent,
                                    ),
                                  )
                                : null,
                            child: ImageBlockWidget(
                              block: block,
                              onChanged: (b) => _updateBlock(index, b),
                              onDelete: () => _removeBlock(index),
                            ),
                          ),
                        );
                      }
                      return GestureDetector(
                        onTap: () {
                          _getFocusNode(block.id).requestFocus();
                          setState(() => _selectedBlockId = block.id);
                        },
                        behavior: HitTestBehavior.translucent,
                        child:
                            BlockWidget(
                              key: ValueKey(block.id),
                              block: block,
                              onChanged: (b) => _updateBlock(index, b),
                              onDelete: () => _removeBlock(index),
                              onAddBelow: (type) => _addBlock(type, index),
                              focusNode: _getFocusNode(block.id),
                              onSelectionChanged: (val) {
                                _currentSelection = val;
                                // No setState needed just for tracking, unless UI depends on it
                              },
                            ).animate(
                              target: _selectedBlockId == block.id ? 1 : 0,
                            ), // Removed shimmer
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            if (_showFormatting && _selectedBlockId != null)
              FormattingToolbar(
                onHeaderChanged: (level) {
                  final currentLevel =
                      _blocks
                          .firstWhere((b) => b.id == _selectedBlockId)
                          .level ??
                      0;
                  if (currentLevel == level)
                    _changeBlockType(BlockType.text);
                  else
                    _changeBlockType(BlockType.heading, level: level);
                },
                onChecklist: () => _changeBlockType(BlockType.todo),
                onBullet: () => _changeBlockType(BlockType.bullet),
              ),

            // Bottom Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getColor(_pageColor) == AppColors.noteDefault
                    ? Theme.of(context).scaffoldBackgroundColor
                    : _getColor(_pageColor),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add_box_outlined,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: _showAddMenu,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.palette_outlined,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: _showPalette,
                    ),
                    Expanded(
                      child: Text(
                        "Edited now",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).disabledColor,
                          fontSize: 10,
                        ),
                      ),
                    ), // Center text
                    IconButton(
                      icon: Icon(
                        Icons.text_format,
                        color: _showFormatting
                            ? Colors.blueAccent
                            : Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        // Only toggle if block selected
                        if (_selectedBlockId != null) {
                          setState(() => _showFormatting = !_showFormatting);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Theme.of(context).cardColor,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                  title: Text(
                                    "Delete",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx); // Close menu
                                    context.read<PagesBloc>().add(
                                      PageDeleted(widget.page.id),
                                    );
                                    context.read<PagesBloc>().add(
                                      const PageSelectionCleared(),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.archive_outlined,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                  title: Text(
                                    "Archive",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    context.read<PagesBloc>().add(
                                      PageArchived(widget.page.id),
                                    );
                                    context.read<PagesBloc>().add(
                                      const PageSelectionCleared(),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.share,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                  title: Text(
                                    "Send",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _sharePage();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateAIImage() {
    showDialog(
      context: context,
      builder: (context) {
        String prompt = '';
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Generate AI Image',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter prompt (e.g., "Cyberpunk city")',
              hintStyle: TextStyle(color: Theme.of(context).hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            onChanged: (value) => prompt = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (prompt.isNotEmpty) {
                  final encodedPrompt = Uri.encodeComponent(prompt);
                  final imageUrl =
                      'https://image.pollinations.ai/prompt/$encodedPrompt';

                  if (_selectedBlockId == null) {
                    _addBlock(BlockType.image, _blocks.length - 1, imageUrl);
                  } else {
                    final index = _blocks.indexWhere(
                      (b) => b.id == _selectedBlockId,
                    );
                    _addBlock(BlockType.image, index, imageUrl);
                  }
                }
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sharePage() async {
    final title = _titleController.text;
    final buffer = StringBuffer();
    if (title.isNotEmpty) buffer.writeln(title);
    buffer.writeln(); // Empty line

    for (final block in _blocks) {
      if (block.type == BlockType.todo) {
        final isChecked = block.isChecked ?? false;
        buffer.writeln((isChecked ? '[x] ' : '[ ] ') + block.content);
      } else if (block.type == BlockType.image) {
        buffer.writeln('[Image: ${block.content}]');
      } else {
        buffer.writeln(block.content);
      }
      buffer.writeln();
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) return;

    await Share.share(text);
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  const FullScreenImageViewer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final isNetwork = imagePath.startsWith('http');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: isNetwork
              ? Image.network(
                  imagePath,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white24,
                    size: 48,
                  ),
                )
              : Image.file(File(imagePath)),
        ),
      ),
    );
  }
}
