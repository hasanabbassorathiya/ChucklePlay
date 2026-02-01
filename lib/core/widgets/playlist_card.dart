import 'package:lumio/l10n/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:lumio/models/playlist_model.dart';
import 'package:lumio/utils/playlist_utils.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableControlBuilder(
      onPressed: onTap,
      builder: (context, state) {
        final isFocused = state.isFocused;
        return AnimatedScale(
          scale: isFocused ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isFocused
                  ? Border.all(color: const Color(0xFFE50914), width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Card(
              elevation: isFocused ? 4 : 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _PlaylistIcon(type: playlist.type),
                    const SizedBox(width: 16),
                    Expanded(child: _PlaylistInfo(playlist: playlist, isFocused: isFocused)),
                    _PlaylistMenu(onDelete: onDelete, onEdit: onEdit),
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

class _PlaylistIcon extends StatelessWidget {
  final PlaylistType type;

  const _PlaylistIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: PlaylistUtils.getPlaylistColor(type),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(
        PlaylistUtils.getPlaylistIcon(type),
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _PlaylistInfo extends StatelessWidget {
  final Playlist playlist;
  final bool isFocused;

  const _PlaylistInfo({required this.playlist, this.isFocused = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          playlist.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isFocused ? const Color(0xFFE50914) : null,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _TypeChip(type: playlist.type),
            const SizedBox(width: 8),
            const Icon(Icons.access_time, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              PlaylistUtils.formatDate(playlist.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        if (playlist.url != null) ...[
          const SizedBox(height: 4),
          Text(
            playlist.url!,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final PlaylistType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = PlaylistUtils.getPlaylistColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _PlaylistMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _PlaylistMenu({required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('Edit', style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(context.loc.delete, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'delete') {
          onDelete();
        } else if (value == 'edit') {
          onEdit();
        }
      },
    );
  }
}
