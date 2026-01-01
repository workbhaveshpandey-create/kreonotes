import 'package:flutter/material.dart';
import '../../domain/block_model.dart';
import '../../../../app/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'styles_controller.dart';

class BlockWidget extends StatefulWidget {
  final BlockModel block;
  final ValueChanged<BlockModel> onChanged;
  final VoidCallback onDelete;
  final ValueChanged<BlockType> onAddBelow;
  final ValueChanged<TextSelection>? onSelectionChanged;
  final FocusNode? focusNode;

  const BlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onDelete,
    required this.onAddBelow,
    this.onSelectionChanged,
    this.focusNode,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> {
  late StylesController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = StylesController(
      text: widget.block.content,
      spans: widget.block.spans,
      baseStyle:
          const TextStyle(), // Will be overridden by input decoration style usually, but needed for controller
    );
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onSelectionChange);
  }

  void _onSelectionChange() {
    if (_focusNode.hasFocus) {
      widget.onSelectionChanged?.call(_controller.selection);
    }
  }

  @override
  void didUpdateWidget(covariant BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content &&
        _controller.text != widget.block.content) {
      _controller.text = widget.block.content;
    }
    // Update spans if they changed (crucial for formatting updates)
    if (oldWidget.block.spans != widget.block.spans) {
      // We can't easily update spans on an existing controller usually without recreation or a setter
      // Let's recreate (simple) or add a setter. Recreating is safer for state sync.
      // But recreation might lose cursor?
      // Better: Add a setter to StylesController (I need to modify it first? No, I can just access spans list if mutable?)
      // Actually, StylesController is final spans.
      // Let's recreate for now.
      final selection = _controller.selection;
      _controller = StylesController(
        text: widget.block.content,
        spans: widget.block.spans,
        baseStyle: const TextStyle(),
      );
      _controller.selection = selection;
    }
    if (widget.focusNode != null && widget.focusNode != _focusNode) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode = widget.focusNode!;
      _focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    _controller.removeListener(_onSelectionChange);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    widget.onChanged(widget.block.copyWith(content: value));
  }

  @override
  Widget build(BuildContext context) {
    final isSummary =
        widget.block.type == BlockType.callout ||
        widget.block.content.startsWith('✨');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(
        bottom: isSummary ? 16 : 4,
        top: isSummary ? 16 : 0,
      ),
      padding: isSummary ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: isSummary
          ? BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            )
          : null, // Clean canvas for text
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Better vertical alignment
        children: [
          // Content
          Expanded(child: _buildContent(isSummary)),

          // Delete Action (Only show if focused or media, and NOT summary which might need long press)
          if (_focusNode.hasFocus && !isSummary)
            Padding(
              padding: const EdgeInsets.only(left: 8), // More space
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18, // Slightly larger
                  color: Theme.of(context).disabledColor,
                ),
                onPressed: widget.onDelete,
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isSummary) {
    if (isSummary) {
      return SelectableText(
        widget.block.content,
        style: AppTextStyles.bodyMedium(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ).copyWith(height: 1.6),
      ).animate().fadeIn(duration: 600.ms);
    }

    switch (widget.block.type) {
      case BlockType.text:
      case BlockType.callout: // Fallback if not summary styled
        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: _getTextStyle(
            AppTextStyles.blockText(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          decoration: InputDecoration(
            hintText: 'Type something...',
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          maxLines: null,
          onChanged: _onTextChanged,
          onSubmitted: (_) => widget.onAddBelow(BlockType.text),
        );

      case BlockType.heading:
        TextStyle baseStyle;
        double fontSize;
        String hint;

        switch (widget.block.level) {
          case 1:
            baseStyle = AppTextStyles.headlineMedium(
              color: Theme.of(context).textTheme.titleLarge?.color,
            );
            fontSize = 28;
            hint = 'Heading 1';
            break;
          case 2:
            baseStyle = AppTextStyles.headlineSmall(
              color: Theme.of(context).textTheme.titleLarge?.color,
            );
            fontSize = 24;
            hint = 'Heading 2';
            break;
          case 3:
            baseStyle = AppTextStyles.titleLarge(
              color: Theme.of(context).textTheme.titleLarge?.color,
            );
            fontSize = 20;
            hint = 'Heading 3';
            break;
          default:
            baseStyle = AppTextStyles.headlineMedium(
              color: Theme.of(context).textTheme.titleLarge?.color,
            );
            fontSize = 24;
            hint = 'Heading';
        }

        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: _getTextStyle(baseStyle.copyWith(fontSize: fontSize)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: fontSize,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero, // Important for symmetry
          ),
          maxLines: null,
          onChanged: _onTextChanged,
          onSubmitted: (_) => widget.onAddBelow(BlockType.text),
        );

      case BlockType.todo:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: widget.block.isChecked ?? false,
                onChanged: (val) {
                  widget.onChanged(widget.block.copyWith(isChecked: val));
                },
                activeColor: Colors.blueAccent,
                side: BorderSide(
                  color: Theme.of(context).unselectedWidgetColor,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style:
                    _getTextStyle(
                      AppTextStyles.blockText(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ).copyWith(
                      decoration: (widget.block.isChecked ?? false)
                          ? TextDecoration.lineThrough
                          : null,
                      color: (widget.block.isChecked ?? false)
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                decoration: InputDecoration(
                  hintText: 'List item',
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(
                    top: 2,
                  ), // Align with checkbox
                ),
                maxLines: null,
                onChanged: _onTextChanged,
                onSubmitted: (_) => widget.onAddBelow(BlockType.todo),
              ),
            ),
          ],
        );

      case BlockType.bullet:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Icon(
                Icons.circle,
                size: 6,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: _getTextStyle(
                  AppTextStyles.blockText(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                decoration: InputDecoration(
                  hintText: 'List item',
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                onChanged: _onTextChanged,
                onSubmitted: (_) => widget.onAddBelow(BlockType.bullet),
              ),
            ),
          ],
        );

      case BlockType.image:
        return const Text(
          "Image should be handled by ImageBlockWidget",
        ); // Logic in PageEditorScreen

      case BlockType.divider:
        return Divider(color: Theme.of(context).dividerColor);

      default:
        return const Text('Unknown Block');
    }
  }

  TextStyle _getTextStyle(TextStyle baseStyle) {
    final metadata = widget.block.metadata ?? {};
    Color color = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    switch (metadata['color']) {
      case 'red':
        color = Colors.redAccent;
        break;
      case 'orange':
        color = Colors.orangeAccent;
        break;
      case 'green':
        color = Colors.greenAccent;
        break;
      case 'blue':
        color = Colors.blueAccent;
        break;
      case 'purple':
        color = Colors.purpleAccent;
        break;
      default:
        color = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    }

    if (widget.block.isChecked == true) {
      color = color.withOpacity(0.5);
    }

    FontWeight weight = (metadata['bold'] == true)
        ? FontWeight.bold
        : baseStyle.fontWeight ?? FontWeight.normal;
    FontStyle style = (metadata['italic'] == true)
        ? FontStyle.italic
        : baseStyle.fontStyle ?? FontStyle.normal;

    return baseStyle.copyWith(
      color: color,
      fontWeight: weight,
      fontStyle: style,
    );
  }
}
