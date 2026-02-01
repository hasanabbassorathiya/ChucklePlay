import 'package:lumio/features/home/home_screen.dart';
import 'package:lumio/features/playlist/playlist_type_screen.dart';
import 'package:lumio/l10n/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:provider/provider.dart';
import '../../controllers/playlist_controller.dart';
import '../home/widgets/empty_state_widget.dart';
import '../../models/playlist_model.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.my_playlists),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistTypeScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlaylistController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.playlists.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.playlist_play_rounded,
              title: context.loc.empty_playlist_title,
              description: context.loc.empty_playlist_message,
              buttonText: context.loc.empty_playlist_button,
              onButtonPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlaylistTypeScreen()),
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.playlists.length,
            itemBuilder: (context, index) {
              final playlist = controller.playlists[index];
              return _PlaylistTile(playlist: playlist);
            },
          );
        },
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FocusableControlBuilder(
        onPressed: () {
          final controller = context.read<PlaylistController>();
          controller.selectPlaylist(playlist);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
        builder: (context, state) {
          final isFocused = state.isFocused;

          return AnimatedScale(
            scale: isFocused ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: isFocused
                    ? theme.colorScheme.primaryContainer
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: isFocused
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: playlist.type == PlaylistType.xtream
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    playlist.type == PlaylistType.xtream
                        ? Icons.stream
                        : Icons.playlist_play,
                    color: playlist.type == PlaylistType.xtream
                        ? Colors.blue
                        : Colors.green,
                    size: 28,
                  ),
                ),
                title: Text(
                  playlist.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      playlist.type == PlaylistType.xtream ? 'Xtream Codes' : 'M3U Playlist',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    if (playlist.url != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        playlist.url!,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          );
        },
      ),
    );
  }
}
