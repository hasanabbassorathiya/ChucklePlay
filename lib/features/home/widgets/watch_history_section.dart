import 'package:lumio/l10n/localization_extension.dart';
import 'package:lumio/features/home/widgets/watch_history_card.dart';
import 'package:flutter/material.dart';
import 'package:lumio/models/watch_history.dart';

class WatchHistorySection extends StatelessWidget {
  final String title;
  final List<WatchHistory> histories;
  final double cardWidth;
  final double cardHeight;
  final bool showProgress;
  final Function(WatchHistory)? onHistoryTap;
  final Function(WatchHistory)? onHistoryRemove;
  final VoidCallback? onSeeAllTap;

  const WatchHistorySection({
    super.key,
    required this.title,
    required this.histories,
    required this.cardWidth,
    required this.cardHeight,
    this.showProgress = false,
    this.onHistoryTap,
    this.onHistoryRemove,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (histories.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (onSeeAllTap != null && histories.length > 5)
                TextButton(
                  onPressed: onSeeAllTap,
                  child: Text(
                    context.loc.see_all,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: cardHeight + 16,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: histories.length > 10 ? 10 : histories.length,
            itemBuilder: (context, index) {
              final history = histories[index];
              return WatchHistoryCard(
                history: history,
                width: cardWidth,
                height: cardHeight,
                showProgress: showProgress,
                onTap: () => onHistoryTap?.call(history),
                onRemove: () => onHistoryRemove?.call(history),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
