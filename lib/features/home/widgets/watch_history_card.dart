import 'package:lumio/utils/app_themes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:lumio/models/content_type.dart';
import 'package:lumio/models/watch_history.dart';

class WatchHistoryCard extends StatelessWidget {
  final WatchHistory history;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showProgress;

  const WatchHistoryCard({
    super.key,
    required this.history,
    required this.width,
    required this.height,
    this.onTap,
    this.onRemove,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableControlBuilder(
      onPressed: onTap,
      builder: (context, state) {
        final isFocused = state.isFocused;
        return AnimatedScale(
          scale: isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: width,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isFocused
                  ? Border.all(color: AppThemes.primaryAccent, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: AppThemes.primaryAccent.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              color: isFocused ? theme.colorScheme.surfaceContainerHighest : theme.cardTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Stack(
                children: [
                  // Background/Thumbnail
                  _buildThumbnail(theme),

                  // Remove Button
                  if (onRemove != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: theme.colorScheme.onSurface, size: 16),
                        ),
                      ),
                    ),

                  // Progress Bar (if applicable)
                  if (showProgress &&
                      history.watchDuration != null &&
                      history.totalDuration != null)
                    Positioned(
                      bottom: 30,
                      left: 8,
                      right: 8,
                      child: _buildProgressBar(theme),
                    ),

                  // Content Info
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            theme.scaffoldBackgroundColor.withOpacity(0.9)
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            history.title,
                            style: TextStyle(
                              color: isFocused ? AppThemes.primaryAccent : theme.colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    if (history.imagePath != null && history.imagePath!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: history.imagePath!,
        width: double.infinity,
        height: double.infinity,
        fit: _getFitForContentType(),
        placeholder: (context, url) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _buildDefaultThumbnail(theme),
      );
    } else {
      return _buildDefaultThumbnail(theme);
    }
  }

  BoxFit _getFitForContentType() {
    // Canlı yayınlar için contain kullan (logolar için)
    if (history.contentType == ContentType.liveStream) {
      return BoxFit.contain;
    }
    // Film ve diziler için cover kullan (posterler için)
    return BoxFit.cover;
  }

  Widget _buildDefaultThumbnail(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getContentTypeColor(history.contentType).withOpacity(0.8),
            _getContentTypeColor(history.contentType),
          ],
        ),
      ),
      child: Icon(
        _getContentTypeIcon(history.contentType),
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progress = history.totalDuration!.inMilliseconds.isInfinite
        ? 0.0
        : (history.watchDuration!.inMilliseconds /
              history.totalDuration!.inMilliseconds);

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress.isInfinite || progress.isNaN ? 0 : progress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: const AlwaysStoppedAnimation<Color>(AppThemes.primaryAccent),
          minHeight: 3,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(history.watchDuration!),
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 10),
            ),
            Text(
              _formatDuration(history.totalDuration!),
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Color _getContentTypeColor(ContentType type) {
    switch (type) {
      case ContentType.liveStream:
        return Colors.red;
      case ContentType.vod:
        return Colors.blue;
      case ContentType.series:
        return Colors.green;
    }
  }

  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.liveStream:
        return Icons.live_tv;
      case ContentType.vod:
        return Icons.movie;
      case ContentType.series:
        return Icons.tv;
    }
  }

  String _getContentTypeText(ContentType type) {
    switch (type) {
      case ContentType.liveStream:
        return 'CANLI';
      case ContentType.vod:
        return 'FİLM';
      case ContentType.series:
        return 'DİZİ';
    }
  }

  String _formatLastWatched(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}g önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}dk önce';
    } else {
      return 'Az önce';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }
}
