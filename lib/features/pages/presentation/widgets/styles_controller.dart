import 'package:flutter/material.dart';
import '../../domain/style_span.dart';
import '../../domain/block_model.dart'; // For StyleType enum if needed

class StylesController extends TextEditingController {
  final List<StyleSpan> spans;
  final TextStyle baseStyle;

  StylesController({super.text, required this.spans, required this.baseStyle});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // If no spans, return simple text
    if (spans.isEmpty) {
      return TextSpan(style: style ?? baseStyle, text: text);
    }

    final List<TextSpan> children = [];

    // NOTE: This implementation assumes non-overlapping spans for simplicity V1.
    // For overlapping (e.g., Bold + Color), we'd need a more complex stack-based builder.
    // Given the request is "Change color of one word", we'll treat styles as potentially layered but we'll try to find segments.

    // Better approach: Character-level styling array.
    // 1. Create mapping of Index -> List<StyleSpan>
    // 2. Iterate characters and group contiguous identical styles.

    if (text.isEmpty) return const TextSpan();

    // Map each character index to a list of applicable styles
    final List<List<StyleSpan>> charStyles = List.generate(
      text.length,
      (_) => [],
    );

    for (final span in spans) {
      for (int i = span.start; i < span.end; i++) {
        if (i < text.length) {
          charStyles[i].add(span);
        }
      }
    }

    // Build segments
    int start = 0;
    while (start < text.length) {
      int end = start + 1;
      // Find end of current style segment
      while (end < text.length &&
          _areStylesEqual(charStyles[start], charStyles[end])) {
        end++;
      }

      final segmentText = text.substring(start, end);
      final segmentStyles = charStyles[start];

      children.add(
        TextSpan(
          text: segmentText,
          style: _mergeStyles(style ?? baseStyle, segmentStyles),
        ),
      );

      start = end;
    }

    return TextSpan(style: style, children: children);
  }

  bool _areStylesEqual(List<StyleSpan> a, List<StyleSpan> b) {
    if (a.length != b.length) return false;
    // Simplistic check: assumes order doesn't matter or is consistent
    // Ideally use Set comparison
    final setA = a.map((s) => '${s.type}-${s.value}').toSet();
    final setB = b.map((s) => '${s.type}-${s.value}').toSet();
    return setA.length == setB.length && setA.containsAll(setB);
  }

  TextStyle _mergeStyles(TextStyle base, List<StyleSpan> spans) {
    TextStyle style = base;
    for (final span in spans) {
      switch (span.type) {
        case StyleType.bold:
          style = style.copyWith(fontWeight: FontWeight.bold);
          break;
        case StyleType.italic:
          style = style.copyWith(fontStyle: FontStyle.italic);
          break;
        case StyleType.underline:
          style = style.copyWith(decoration: TextDecoration.underline);
          break;
        case StyleType.color:
          if (span.value != null) {
            final color = _parseColor(span.value!);
            if (color != null) {
              style = style.copyWith(color: color);
            }
          }
          break;
      }
    }
    return style;
  }

  Color? _parseColor(String value) {
    switch (value) {
      case 'red':
        return Colors.redAccent;
      case 'orange':
        return Colors.orangeAccent;
      case 'yellow':
        return Colors.yellowAccent;
      case 'green':
        return Colors.greenAccent;
      case 'cyan':
        return Colors.cyanAccent;
      case 'blue':
        return Colors.blueAccent;
      case 'purple':
        return Colors.purpleAccent;
      case 'pink':
        return Colors.pinkAccent;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      case 'default':
      default:
        return null;
    }
  }
}
