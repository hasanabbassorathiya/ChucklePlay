import 'package:flutter/material.dart';
import 'package:lumio/l10n/localization_extension.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';

class ColorPickerTileWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final ValueChanged<Color> onChanged;

  const ColorPickerTileWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableControlBuilder(
      onPressed: () => _showColorPickerDialog(context),
      builder: (context, state) {
        final isFocused = state.isFocused;
        final theme = Theme.of(context);

        return AnimatedScale(
          scale: isFocused ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              color: isFocused ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(12),
              border: isFocused
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Icon(
                icon,
                size: 20,
                color: isFocused ? theme.colorScheme.primary : null,
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isFocused ? FontWeight.bold : FontWeight.w500,
                  color: isFocused ? theme.colorScheme.primary : null,
                ),
              ),
              trailing: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFocused ? theme.colorScheme.primary : theme.colorScheme.outline,
                    width: isFocused ? 2 : 1.5,
                  ),
                ),
              ),
              onTap: () => _showColorPickerDialog(context),
            ),
          ),
        );
      },
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    final colors = [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      const Color(0xffffffff),
      const Color(0xaa000000),
      const Color(0x80000000),
      const Color(0x40000000),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc.pick_color),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors
              .map(
                (c) => FocusableControlBuilder(
                  onPressed: () {
                    onChanged(c);
                    Navigator.pop(context);
                  },
                  builder: (context, state) {
                    final isFocused = state.isFocused;
                    return GestureDetector(
                      onTap: () {
                        onChanged(c);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFocused
                                ? Theme.of(context).primaryColor
                                : (color == c
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey),
                            width: (isFocused || color == c) ? 3 : 1,
                          ),
                          boxShadow: isFocused
                              ? [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.loc.cancel),
          ),
        ],
      ),
    );
  }
}
