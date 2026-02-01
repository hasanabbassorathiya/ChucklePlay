import 'package:flutter/material.dart';

/// A luxury error dialog for video player failures
/// Designed with modern Material 3 components and TV/set-top box aesthetic
class PlayerErrorDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const PlayerErrorDialog({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String errorMessage,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => PlayerErrorDialog(
        errorMessage: errorMessage,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }

  String _getUserFriendlyMessage(String error) {
    if (error.toLowerCase().contains('failed to open') ||
        error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection')) {
      return 'Connection Error';
    } else if (error.toLowerCase().contains('no video') ||
        error.toLowerCase().contains('codec')) {
      return 'Playback Error';
    } else if (error.toLowerCase().contains('timeout')) {
      return 'Request Timeout';
    } else if (error.toLowerCase().contains('not found') ||
        error.toLowerCase().contains('404')) {
      return 'Content Not Found';
    } else if (error.toLowerCase().contains('unauthorized') ||
        error.toLowerCase().contains('403')) {
      return 'Access Denied';
    }
    return 'Playback Error';
  }

  String _getDetailedMessage(String error) {
    if (error.length > 150) {
      return '${error.substring(0, 150)}...';
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final errorColor = theme.colorScheme.error;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    errorColor.withOpacity(0.2),
                    errorColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: errorColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getUserFriendlyMessage(errorMessage),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Error details
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey[800]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getDetailedMessage(errorMessage),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      if (onDismiss != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDismiss?.call();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              'Dismiss',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: onDismiss != null ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onRetry?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 20),
                              const SizedBox(width: 8),
                            Text(
                              'Retry',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
