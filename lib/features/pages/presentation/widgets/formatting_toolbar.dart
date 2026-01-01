import 'package:flutter/material.dart';

class FormattingToolbar extends StatelessWidget {
  final ValueChanged<int> onHeaderChanged;
  final VoidCallback onChecklist;
  final VoidCallback onBullet;

  const FormattingToolbar({
    super.key,
    required this.onHeaderChanged,
    required this.onChecklist,
    required this.onBullet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildHeaderBtn(context, 'H1', 1),
          _buildHeaderBtn(context, 'H2', 2),
          _buildHeaderBtn(context, 'H3', 3),
          _buildDivider(context),
          _buildIconBtn(
            context,
            Icons.check_box_outlined,
            'Checkbox',
            onChecklist,
          ),
          _buildIconBtn(
            context,
            Icons.format_list_bulleted,
            'Bullets',
            onBullet,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBtn(BuildContext context, String text, int level) {
    return InkWell(
      onTap: () => onHeaderChanged(level),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildIconBtn(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 20),
        ),
      ),
    );
  }
}
