import 'package:lumio/l10n/localization_extension.dart';
import 'package:lumio/services/event_bus.dart';
import 'package:lumio/services/player_state.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:lumio/features/settings/widgets/subtitle_customization_list.dart';

class VideoSettingsWidget extends StatefulWidget {
  final VoidCallback onClose;

  const VideoSettingsWidget({super.key, required this.onClose});

  @override
  State<VideoSettingsWidget> createState() => _VideoSettingsWidgetState();
}

class _VideoSettingsWidgetState extends State<VideoSettingsWidget> {
  int _selectedTab = 0; // 0: Audio, 1: Subtitle, 2: Video

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = (screenWidth / 3).clamp(300.0, 400.0);

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Container(
                width: panelWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(context, theme),
                    _buildTabs(context, theme),
                    Expanded(
                      child: _buildTrackList(context, theme),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.loc.settings,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildTabItem(context, 0, Icons.audiotrack_rounded, context.loc.audio_track)),
          Expanded(child: _buildTabItem(context, 1, Icons.subtitles_rounded, context.loc.subtitle_track)),
          Expanded(child: _buildTabItem(context, 2, Icons.style_rounded, context.loc.style_settings)),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    final theme = Theme.of(context);

    return FocusableControlBuilder(
      onPressed: () => setState(() => _selectedTab = index),
      builder: (context, state) {
        final isFocused = state.isFocused;
        return AnimatedScale(
          scale: isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.surface
                  : (isFocused ? theme.colorScheme.surface.withValues(alpha: 0.5) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: isFocused ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : (isFocused
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackList(BuildContext context, ThemeData theme) {
    if (_selectedTab == 0) {
      return _buildAudioTracks(context, theme);
    } else if (_selectedTab == 1) {
      return _buildSubtitleTracks(context, theme);
    } else if (_selectedTab == 2) {
      return const SubtitleCustomizationList(showPreview: false);
    } else {
      return _buildVideoTracks(context, theme);
    }
  }

  Widget _buildAudioTracks(BuildContext context, ThemeData theme) {
    final tracks = PlayerState.audios;
    if (tracks.isEmpty) {
      return Center(child: Text(context.loc.no_tracks_available));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isSelected = PlayerState.selectedAudio == track;

        return _buildTrackTile(
          context,
          title: track.language ?? track.title ?? 'Track ${index + 1}',
          subtitle: track.id,
          isSelected: isSelected,
          onTap: () {
            EventBus().emit('audio_track_changed', track);
            setState(() {
              PlayerState.selectedAudio = track;
            });
          },
        );
      },
    );
  }

  Widget _buildSubtitleTracks(BuildContext context, ThemeData theme) {
    final tracks = PlayerState.subtitles;
    if (tracks.isEmpty) {
      return Center(child: Text(context.loc.no_tracks_available));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isSelected = PlayerState.selectedSubtitle == track;

        return _buildTrackTile(
          context,
          title: track.language ?? track.title ?? 'Track ${index + 1}',
          subtitle: track.id,
          isSelected: isSelected,
          onTap: () {
            EventBus().emit('subtitle_track_changed', track);
            setState(() {
              PlayerState.selectedSubtitle = track;
            });
          },
        );
      },
    );
  }

  Widget _buildVideoTracks(BuildContext context, ThemeData theme) {
    final tracks = PlayerState.videos;
    if (tracks.isEmpty) {
      return Center(child: Text(context.loc.no_tracks_available));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isSelected = PlayerState.selectedVideo == track;

        return _buildTrackTile(
          context,
          title: '${track.w}x${track.h}',
          subtitle: '${track.id} - ${track.codec}',
          isSelected: isSelected,
          onTap: () {
            EventBus().emit('video_track_changed', track);
            setState(() {
              PlayerState.selectedVideo = track;
            });
          },
        );
      },
    );
  }

  Widget _buildTrackTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FocusableControlBuilder(
        onPressed: onTap,
        builder: (context, state) {
          final isFocused = state.isFocused;
          return Container(
            decoration: BoxDecoration(
              color: isFocused
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : (isSelected ? theme.colorScheme.primary.withValues(alpha: 0.05) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFocused
                    ? theme.colorScheme.primary
                    : (isSelected ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.dividerColor.withValues(alpha: 0.2)),
                width: isFocused || isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? theme.colorScheme.primary : theme.disabledColor,
                size: 20,
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: subtitle != null ? Text(subtitle) : null,
              trailing: isFocused
                  ? Icon(Icons.touch_app, color: theme.colorScheme.primary, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

