import 'package:lumio/features/home/widgets/favorites_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/playlist_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../home/widgets/empty_state_widget.dart';
import '../../utils/responsive_helper.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistController>(
      builder: (context, playlistController, child) {
        if (playlistController.playlists.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.favorite_border_rounded,
            title: 'No Favorites',
            description: 'Add a playlist to start bookmarking your favorite channels.',
          );
        }

        return ChangeNotifierProvider(
          create: (_) => FavoritesController()..loadFavorites(),
          child: Consumer<FavoritesController>(
            builder: (context, favoritesController, child) {
              if (favoritesController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (favoritesController.favorites.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.favorite_border_rounded,
                  title: 'No Favorites Found',
                  description: 'When you find something you like, add it to favorites to see it here.',
                );
              }

              return Scaffold(
                appBar: AppBar(title: const Text('Favorites')),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: FavoritesSection(
                    favorites: favoritesController.favorites,
                    cardWidth: ResponsiveHelper.getStbCardWidth(context),
                    cardHeight: ResponsiveHelper.getCardHeight(context),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
