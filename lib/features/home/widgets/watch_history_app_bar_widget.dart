import 'package:lumio/l10n/localization_extension.dart';
import 'package:flutter/material.dart';

class WatchHistoryAppBar extends StatelessWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onClearAll;
  final VoidCallback? onRefreshFavorites;

  const WatchHistoryAppBar({
    super.key,
    this.onRefresh,
    this.onClearAll,
    this.onRefreshFavorites,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(
        context.loc.history,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      floating: true,
      snap: true,
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          iconColor: theme.colorScheme.onSurface,
          onSelected: (action) => _handleMenuAction(action, context),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text(context.loc.refresh),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  const Icon(Icons.clear_all, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    context.loc.clear_all,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'refresh':
        onRefresh?.call();
        onRefreshFavorites?.call();
        break;
      case 'clear_all':
        _onClearAllTap(context);
        break;
    }
  }

  void _onClearAllTap(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.clear_all),
        content: Text(context.loc.clear_all_confirmation_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClearAll?.call();
            },
            child: Text(
              context.loc.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
