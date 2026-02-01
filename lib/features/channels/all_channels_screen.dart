import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/playlist_controller.dart';
import '../home/widgets/empty_state_widget.dart';
import '../channels/m3u_items_screen.dart';
import '../../models/playlist_model.dart';
import '../../services/app_state.dart';

class AllChannelsScreen extends StatelessWidget {
  const AllChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.playlists.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.list_alt_rounded,
            title: 'No Content',
            description: 'Add a playlist to browse channels.',
          );
        }

        final playlist = controller.currentPlaylist ?? controller.playlists.first;

        if (playlist.type == PlaylistType.m3u) {
          return M3uItemsScreen(m3uItems: AppState.m3uItems ?? []);
        } else {
          // For Xtream, we might want a similar grid/list view
          // For now, redirecting to a placeholder or existing logic
          return const Center(
            child: Text(
              'Xtream Channels Browser Coming Soon',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
      },
    );
  }
}
