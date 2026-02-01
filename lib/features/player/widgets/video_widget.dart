import 'package:lumio/features/player/widgets/premium_player_controls.dart';
import 'package:lumio/repositories/user_preferences.dart';
import 'package:lumio/services/player_state.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoWidget extends StatefulWidget {
  final VideoController controller;
  final SubtitleViewConfiguration subtitleViewConfiguration;
  final VoidCallback? onBack;

  const VideoWidget({
    super.key,
    required this.controller,
    required this.subtitleViewConfiguration,
    this.onBack,
  });

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Keep loading logic if needed for other settings, but gestures are handled by PremiumPlayerControls or PlayerWidget
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Video(
        controller: widget.controller,
        fit: BoxFit.contain,
        resumeUponEnteringForegroundMode: true,
        pauseUponEnteringBackgroundMode: !PlayerState.backgroundPlay,
        subtitleViewConfiguration: widget.subtitleViewConfiguration,
        controls: (state) => PremiumPlayerControls(
          player: widget.controller.player,
          controller: widget.controller,
          title: PlayerState.title,
          onBack: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

// Backward compatibility wrapper
Widget getVideo(
  BuildContext context,
  VideoController controller,
  SubtitleViewConfiguration subtitleViewConfiguration, {
  VoidCallback? onBack,
}) {
  return VideoWidget(
    controller: controller,
    subtitleViewConfiguration: subtitleViewConfiguration,
    onBack: onBack,
  );
}
