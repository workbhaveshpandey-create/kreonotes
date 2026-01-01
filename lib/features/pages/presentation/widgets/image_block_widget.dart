import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/block_model.dart';
import '../../../../app/theme/app_theme.dart';

class ImageBlockWidget extends StatelessWidget {
  final BlockModel block;
  final Function(BlockModel) onChanged;
  final VoidCallback onDelete;

  const ImageBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = block.content;
    final isNetwork = imagePath.startsWith('http');

    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagePath.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white24,
                      size: 48,
                    ),
                  )
                : isNetwork
                ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.purpleAccent,
                        ),
                      );
                    },
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
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.white24),
                      );
                    },
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white24),
                    ),
                  ),
          ),
        ),
        // Delete button
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
