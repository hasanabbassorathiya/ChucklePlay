import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import '../../controllers/playlist_controller.dart';
import 'general_settings_section.dart';
import 'm3u_playlist_settings_screen.dart';
import 'xtream_code_playlist_settings_screen.dart';
import '../../models/playlist_model.dart';
import 'package:lumio/features/playlist/playlist_type_screen.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistController>(
      builder: (context, controller, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const GeneralSettingsWidget(),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'PLAYLIST SETTINGS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (controller.playlists.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.playlist_add_rounded),
                  title: const Text('No playlists added'),
                  subtitle: const Text('Add your first playlist'),
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlaylistTypeScreen()),
                    );
                  },
                ),
              )
            else
              ...controller.playlists.map((playlist) => _buildPlaylistTile(context, playlist)),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistTile(BuildContext context, Playlist playlist) {
    return FocusableControlBuilder(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => playlist.type == PlaylistType.m3u
                ? M3uPlaylistSettingsScreen(playlist: playlist)
                : XtreamCodePlaylistSettingsScreen(playlist: playlist),
          ),
        );
      },
      builder: (context, state) {
        final isFocused = state.isFocused;
        return AnimatedScale(
          scale: isFocused ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isFocused
                  ? Border.all(color: const Color(0xFFE50914), width: 2)
                  : null,
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Card(
              margin: EdgeInsets.zero,
              color: isFocused ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
              child: ListTile(
                leading: Icon(
                  playlist.type == PlaylistType.m3u ? Icons.playlist_play_rounded : Icons.stream_rounded,
                  color: playlist.type == PlaylistType.m3u ? Colors.green : Colors.blue,
                ),
                title: Text(
                  playlist.name,
                  style: TextStyle(
                    fontWeight: isFocused ? FontWeight.bold : null,
                  ),
                ),
                subtitle: Text(playlist.type == PlaylistType.m3u ? 'M3U Playlist' : 'Xtream Codes'),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ),
        );
      },
    );
  }
}
