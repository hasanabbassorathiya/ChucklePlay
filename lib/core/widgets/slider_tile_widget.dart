import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';

class SliderTileWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const SliderTileWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableControlBuilder(
      onPressed: () {}, // No default action, handled by slider or keys
      onFocusChanged: (context, state) {},
      builder: (context, state) {
        final isFocused = state.isFocused;
        final theme = Theme.of(context);
        final step = (max - min) / divisions;

        if (isFocused) {
          // Handle keyboard events for the slider when the tile is focused
          return Actions(
            actions: {
              IncreaseIntent: CallbackAction<IncreaseIntent>(
                onInvoke: (intent) {
                  final newValue = (value + step).clamp(min, max);
                  onChanged(newValue);
                  return null;
                },
              ),
              DecreaseIntent: CallbackAction<DecreaseIntent>(
                onInvoke: (intent) {
                  final newValue = (value - step).clamp(min, max);
                  onChanged(newValue);
                  return null;
                },
              ),
            },
            child: Shortcuts(
              shortcuts: {
                SingleActivator(LogicalKeyboardKey.arrowRight): IncreaseIntent(),
                SingleActivator(LogicalKeyboardKey.arrowLeft): DecreaseIntent(),
              },
              child: _buildContent(context, theme, isFocused),
            ),
          );
        }

        return AnimatedScale(
          scale: isFocused ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: _buildContent(context, theme, isFocused),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isFocused) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isFocused ? theme.colorScheme.primary.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
        border: isFocused
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst kısım: Icon, Label ve Value
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isFocused ? theme.colorScheme.primary : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isFocused ? FontWeight.bold : FontWeight.w500,
                    color: isFocused ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isFocused ? theme.colorScheme.primary.withOpacity(0.2) : null,
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isFocused ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbColor: isFocused ? theme.colorScheme.primary : null,
              activeTrackColor: isFocused ? theme.colorScheme.primary : null,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class IncreaseIntent extends Intent {}
class DecreaseIntent extends Intent {}
