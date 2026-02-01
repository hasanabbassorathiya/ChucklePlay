import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/playlist_controller.dart';
import 'widgets/empty_state_widget.dart';
import '../../models/playlist_model.dart';
import '../playlist/playlist_type_screen.dart';
import 'stb_dashboard_screen.dart';
import 'm3u_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.playlists.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Home')),
            body: EmptyStateWidget(
              icon: Icons.playlist_add_rounded,
              title: 'No Playlists Found',
              description: 'Add your first Xtream Codes or M3U playlist to start watching.',
              buttonText: 'Add Playlist',
              onButtonPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistTypeScreen()),
              ),
            ),
          );
        }

        final currentPlaylist = controller.currentPlaylist ?? controller.playlists.first;

        // Based on the selected playlist type, show the appropriate dashboard
        // We use the existing screens for now to preserve functionality
        if (currentPlaylist.type == PlaylistType.xtream) {
          return StbDashboardScreen(playlist: currentPlaylist);
        } else {
          return M3UHomeScreen(playlist: currentPlaylist);
        }
      },
    );
  }
}
