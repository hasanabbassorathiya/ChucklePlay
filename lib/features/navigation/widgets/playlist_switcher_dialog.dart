import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lumio/controllers/playlist_controller.dart';
import 'package:lumio/models/playlist_model.dart';
import 'package:lumio/features/playlist/playlist_type_screen.dart';
import 'package:lumio/l10n/localization_extension.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';

class PlaylistSwitcherDialog extends StatelessWidget {
  const PlaylistSwitcherDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistController = context.watch<PlaylistController>();
    final playlists = playlistController.playlists;
    final currentPlaylist = playlistController.currentPlaylist;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Dark Grey
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, theme),
            const Divider(color: Colors.white10, height: 1),
            Flexible(
              child: playlists.isEmpty
                  ? _buildEmptyState(context, theme)
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final isSelected = currentPlaylist?.id == playlist.id;
                        return _buildPlaylistItem(context, theme, playlist, isSelected);
                      },
                    ),
            ),
            const Divider(color: Colors.white10, height: 1),
            _buildFooter(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc.my_playlists,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a playlist to watch',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(
    BuildContext context,
    ThemeData theme,
    Playlist playlist,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: FocusableControlBuilder(
        onPressed: () {
          context.read<PlaylistController>().selectPlaylist(playlist);
          Navigator.of(context).pop();
        },
        builder: (context, state) {
          final isFocused = state.isFocused;
          return AnimatedScale(
            scale: isFocused ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isFocused
                    ? const Color(0xFFE50914).withOpacity(0.1)
                    : (isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFocused
                      ? const Color(0xFFE50914)
                      : (isSelected ? const Color(0xFFE50914).withOpacity(0.5) : Colors.transparent),
                  width: isFocused ? 2 : 1.5,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE50914).withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE50914) : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    playlist.type == PlaylistType.xtream ? Icons.stream : Icons.playlist_play,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                title: Text(
                  playlist.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                    fontWeight: (isSelected || isFocused) ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  playlist.type == PlaylistType.xtream ? 'Xtream Codes' : 'M3U Playlist',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFFE50914))
                    : (isFocused ? const Icon(Icons.play_arrow, color: Color(0xFFE50914)) : null),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.playlist_add_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            context.loc.empty_playlist_title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.loc.empty_playlist_message,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FocusableControlBuilder(
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PlaylistTypeScreen()),
          );
        },
        builder: (context, state) {
          final isFocused = state.isFocused;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isFocused ? const Color(0xFFE50914) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused ? Colors.transparent : Colors.white10,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: isFocused ? Colors.white : const Color(0xFFE50914),
                ),
                const SizedBox(width: 12),
                Text(
                  context.loc.create_new_playlist,
                  style: TextStyle(
                    color: isFocused ? Colors.white : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
