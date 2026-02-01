import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import '../../controllers/epg_controller.dart';
import '../../controllers/playlist_controller.dart';
import '../home/widgets/empty_state_widget.dart';
import '../../models/epg_channel.dart';
import '../../models/epg_program.dart';
import '../../models/content_type.dart';
import '../../models/playlist_content_model.dart';
import '../../models/m3u_item.dart';
import '../../models/live_stream.dart';
import '../../utils/navigate_by_content_type.dart';

class EpgScreen extends StatefulWidget {
  const EpgScreen({super.key});

  @override
  State<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends State<EpgScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEpgData();
    });
  }

  void _loadEpgData() {
    final playlistController =
        Provider.of<PlaylistController>(context, listen: false);
    final currentPlaylist = playlistController.currentPlaylist;

    if (currentPlaylist != null) {
      Provider.of<EpgController>(context, listen: false)
          .loadEpgData(currentPlaylist.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistController>(
      builder: (context, playlistController, child) {
        if (playlistController.playlists.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.schedule_rounded,
            title: 'No TV Guide',
            description: 'Add a playlist to view Electronic Program Guide.',
          );
        }

        if (playlistController.currentPlaylist == null) {
          return const EmptyStateWidget(
            icon: Icons.playlist_play_rounded,
            title: 'No Playlist Selected',
            description: 'Select a playlist to view EPG.',
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('TV Guide'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadEpgData,
              ),
            ],
          ),
          body: Consumer<EpgController>(
            builder: (context, epgController, child) {
              if (epgController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (epgController.channels.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.tv_off_rounded,
                  title: 'No Channels Found',
                  description: 'No EPG channels found for this playlist.',
                );
              }

              return ListView.separated(
                itemCount: epgController.channels.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final channel = epgController.channels[index];
                  final currentProgram = epgController.getCurrentProgram(channel.id);

                  return _EpgChannelTile(
                    channel: channel,
                    currentProgram: currentProgram,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _EpgChannelTile extends StatelessWidget {
  final EpgChannel channel;
  final EpgProgram? currentProgram;

  const _EpgChannelTile({
    required this.channel,
    this.currentProgram,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('HH:mm');

    return FocusableControlBuilder(
      onPressed: () async {
        final epgController =
            Provider.of<EpgController>(context, listen: false);
        final playlistController =
            Provider.of<PlaylistController>(context, listen: false);

        if (playlistController.currentPlaylist == null) return;

        // Show a loading indicator dialog or similar if needed
        // For now, we'll just await.

        try {
          final stream = await epgController.findStreamForChannel(
            channel.id,
            playlistController.currentPlaylist!.id,
          );

          if (!context.mounted) return;

          if (stream != null) {
            ContentItem? contentItem;
            if (stream is M3uItem) {
              contentItem = ContentItem(
                stream.id,
                stream.name ?? 'Unknown',
                stream.tvgLogo ?? '',
                ContentType.liveStream,
                m3uItem: stream,
              );
            } else if (stream is LiveStream) {
              contentItem = ContentItem(
                stream.streamId,
                stream.name,
                stream.streamIcon,
                ContentType.liveStream,
                liveStream: stream,
              );
            }

            if (contentItem != null) {
              navigateByContentType(context, contentItem);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Stream type not supported or invalid')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No stream found for this channel')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error finding stream: $e')),
            );
          }
        }
      },
      builder: (context, state) {
        final isFocused = state.isFocused;
        final isHovered = state.isHovered;

        return AnimatedScale(
          scale: isFocused ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              color: (isFocused || isHovered)
                  ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
                  : null,
              border: isFocused
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    )
                  : Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    image: channel.icon != null
                        ? DecorationImage(
                            image: NetworkImage(channel.icon!),
                            fit: BoxFit.contain,
                          )
                        : null,
                  ),
                  child: channel.icon == null
                      ? Icon(
                          Icons.tv_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Program Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.displayName ?? 'Unknown Channel',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: (isFocused || isHovered) ? theme.colorScheme.primary : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (currentProgram != null) ...[
                        Text(
                          currentProgram!.title,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${dateFormat.format(currentProgram!.start)} - ${dateFormat.format(currentProgram!.stop)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ProgressBar(
                                start: currentProgram!.start,
                                end: currentProgram!.stop,
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          'No Program Information',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),);
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final DateTime start;
  final DateTime end;

  const _ProgressBar({
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalDuration = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;

    // Clamp progress between 0.0 and 1.0
    final progress = (elapsed / totalDuration).clamp(0.0, 1.0);

    if (totalDuration <= 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
        minHeight: 4,
      ),
    );
  }
}
