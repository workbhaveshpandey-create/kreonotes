import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/ai_service.dart';

class AiAssistantWidget extends StatefulWidget {
  final String content;
  final Function(String) onApply;

  const AiAssistantWidget({
    super.key,
    required this.content,
    required this.onApply,
  });

  @override
  State<AiAssistantWidget> createState() => _AiAssistantWidgetState();
}

class _AiAssistantWidgetState extends State<AiAssistantWidget> {
  final AiService _aiService = AiService();
  bool _isLoading = false;
  String? _result;
  String _activeAction = '';

  Future<void> _performAction(
    String action,
    Future<String> Function() apiCall,
  ) async {
    setState(() {
      _isLoading = true;
      _activeAction = action;
      _result = null;
    });

    try {
      final result = await apiCall();
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = 'Error: Failed to generate response';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.purpleAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Assistant',
                style: AppTextStyles.titleMedium(
                  color: Colors.white,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actions
          if (_result == null && !_isLoading)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionChip(
                  '✨ Continue Writing',
                  () => _performAction(
                    'Writing...',
                    () => _aiService.continueWriting(widget.content),
                  ),
                ),
                _buildActionChip(
                  '📝 Summarize',
                  () => _performAction(
                    'Summarizing...',
                    () => _aiService.summarize(widget.content),
                  ),
                ),
                _buildActionChip(
                  '🔧 Fix Grammar',
                  () => _performAction(
                    'Improving...',
                    () => _aiService.improve(widget.content),
                  ),
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.2),

          // Loading State
          if (_isLoading)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.purpleAccent),
                  const SizedBox(height: 16),
                  Text(
                    _activeAction,
                    style: AppTextStyles.bodyMedium(color: Colors.white70),
                  ).animate().fadeIn().shimmer(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

          // Result State
          if (_result != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    _result!,
                    style: AppTextStyles.bodyMedium(color: Colors.white),
                  ),
                ).animate().fadeIn().slideY(begin: 0.2),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _result = null;
                        });
                      },
                      child: Text(
                        'Discard',
                        style: AppTextStyles.labelLarge(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        widget.onApply(_result!);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Insert'),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      labelStyle: AppTextStyles.bodySmall(color: Colors.white),
      backgroundColor: AppColors.surfaceVariant,
      side: const BorderSide(color: Colors.white12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: onTap,
    );
  }
}
