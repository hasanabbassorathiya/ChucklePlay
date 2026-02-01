import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';

class DropdownTileWidget<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const DropdownTileWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableControlBuilder(
      onPressed: () {}, // Dropdown handles tap
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
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isFocused ? FontWeight.bold : FontWeight.w500,
                  color: isFocused ? theme.colorScheme.primary : null,
                ),
              ),
              trailing: SizedBox(
              width: 120,
              child: InputDecorator(
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isFocused
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    items: items,
                    onChanged: onChanged,
                    isExpanded: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: isFocused ? theme.colorScheme.primary : null,
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: isFocused ? theme.colorScheme.primary : null,
                    ),
                    focusColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ),);
      },
    );
  }
}
