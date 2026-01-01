import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<List<Offset>> _lines = [];
  List<Offset> _currentLine = [];
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _saveDrawing() async {
    try {
      RenderRepaintBoundary? boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'drawing_${const Uuid().v4()}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        if (mounted) {
          Navigator.pop(context, file.path); // Return path
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Drawing',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blueAccent),
            onPressed: _saveDrawing,
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: Container(
          color: Theme.of(
            context,
          ).scaffoldBackgroundColor, // Background for the image
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentLine = [details.localPosition];
                _lines.add(_currentLine);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentLine.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              // Line finished
            },
            child: CustomPaint(
              painter: _SketchPainter(
                _lines,
                Theme.of(context).iconTheme.color ?? Colors.white,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  final List<List<Offset>> lines;
  final Color strokeColor;
  _SketchPainter(this.lines, this.strokeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      if (line.isEmpty) continue;
      final path = Path();
      path.moveTo(line.first.dx, line.first.dy);
      for (int i = 1; i < line.length; i++) {
        path.lineTo(line[i].dx, line[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
