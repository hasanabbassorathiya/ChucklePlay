import 'package:lumio/l10n/localization_extension.dart';
import 'package:lumio/features/playlist/new_m3u_playlist_screen.dart';
import 'package:lumio/features/playlist/new_xtream_code_playlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';

class PlaylistTypeScreen extends StatelessWidget {
  const PlaylistTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.loc.create_new_playlist,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        context.loc.select_playlist_type,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        context.loc.select_playlist_message,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 40),
                      _buildPlaylistTypeCard(
                        context,
                        title: 'Xtream Codes',
                        subtitle: context.loc.xtream_code_title,
                        description: context.loc.xtream_code_description,
                        icon: Icons.stream,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NewXtreamCodePlaylistScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildPlaylistTypeCard(
                        context,
                        title: 'M3U Playlist',
                        subtitle: context.loc.m3u_playlist_title,
                        description: context.loc.m3u_playlist_description,
                        icon: Icons.playlist_play,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewM3uPlaylistScreen(),
                            ),
                          );
                        },
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.loc.select_playlist_type_footer,
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FocusableControlBuilder(
      onPressed: onTap,
      builder: (context, state) {
        final isFocused = state.isFocused;
        return AnimatedScale(
          scale: isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isFocused
                  ? Border.all(color: const Color(0xFFE50914), width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Card(
              elevation: isFocused ? 0 : 4, // Hide card elevation when focused to use container shadow
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isFocused ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isFocused ? const Color(0xFFE50914) : color,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: isFocused
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFE50914).withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(icon, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isFocused ? const Color(0xFFE50914) : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isFocused ? const Color(0xFFE50914).withOpacity(0.8) : color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(fontSize: 13, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: isFocused ? const Color(0xFFE50914) : Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
