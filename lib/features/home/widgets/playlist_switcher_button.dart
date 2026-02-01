import 'package:lumio/controllers/playlist_controller.dart';
import 'package:lumio/features/navigation/widgets/playlist_switcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:provider/provider.dart';

class PlaylistSwitcherButton extends StatelessWidget {
  final bool compact;
  final bool isSidebarExpanded;

  const PlaylistSwitcherButton({
    super.key,
    this.compact = false,
    this.isSidebarExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final playlistController = context.watch<PlaylistController>();
    final currentPlaylist = playlistController.currentPlaylist;
    final theme = Theme.of(context);

    return FocusableControlBuilder(
      onPressed: () => showDialog(
        context: context,
        builder: (context) => const PlaylistSwitcherDialog(),
      ),
      builder: (context, state) {
        final isFocused = state.isFocused;

        if (compact) {
          return AnimatedScale(
            scale: isFocused ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: Stack(
                children: [
                  Icon(
                    Icons.playlist_play_rounded,
                    color: isFocused ? theme.colorScheme.primary : null,
                  ),
                  if (currentPlaylist != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE50914),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const PlaylistSwitcherDialog(),
              ),
            ),
          );
        }

        if (!isSidebarExpanded) {
           return AnimatedScale(
             scale: isFocused ? 1.1 : 1.0,
             duration: const Duration(milliseconds: 200),
             child: InkWell(
              onTap: () => showDialog(
                context: context,
                builder: (context) => const PlaylistSwitcherDialog(),
              ),
               child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                 decoration: BoxDecoration(
                    color: isFocused
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isFocused ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                 ),
                 child: Center(
                   child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: currentPlaylist != null ? const Color(0xFFE50914) : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.playlist_play_rounded, size: 20, color: Colors.white),
                   ),
                 ),
               ),
             ),
           );
        }

        return AnimatedScale(
          scale: isFocused ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isFocused
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFocused ? theme.colorScheme.primary : Colors.white10,
                width: isFocused ? 2 : 1,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: currentPlaylist != null ? const Color(0xFFE50914) : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.playlist_play_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentPlaylist?.name ?? 'Select Playlist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      currentPlaylist != null ? 'Active' : 'No playlist',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                size: 18,
                color: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
        ),);
      },
    );
  }
}
