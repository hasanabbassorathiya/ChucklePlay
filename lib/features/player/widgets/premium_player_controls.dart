import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:intl/intl.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/methods/fullscreen.dart';

import 'package:window_manager/window_manager.dart';
import '../../../utils/app_themes.dart';
import '../../../services/player_state.dart';
import '../../../services/event_bus.dart';

class PremiumPlayerControls extends StatefulWidget {
  final Player player;
  final VideoController controller;
  final String title;
  final VoidCallback onBack;

  const PremiumPlayerControls({
    super.key,
    required this.player,
    required this.controller,
    required this.title,
    required this.onBack,
  });

  @override
  State<PremiumPlayerControls> createState() => _PremiumPlayerControlsState();
}

class _PremiumPlayerControlsState extends State<PremiumPlayerControls> {
  bool _visible = true;
  Timer? _hideTimer;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Duration> _durationSubscription;
  late StreamSubscription<bool> _playingSubscription;
  late StreamSubscription<bool> _bufferingSubscription;
  late StreamSubscription<double> _volumeSubscription;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _buffering = false;
  double _volume = 100.0;
  String _currentTimeStr = '';
  late Timer _clockTimer;

  @override
  void initState() {
    super.initState();
    _position = widget.player.state.position;
    _duration = widget.player.state.duration;
    _playing = widget.player.state.playing;
    _buffering = widget.player.state.buffering;
    _volume = widget.player.state.volume;

    _positionSubscription = widget.player.stream.position.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durationSubscription = widget.player.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _playingSubscription = widget.player.stream.playing.listen((p) {
      if (mounted) setState(() => _playing = p);
    });
    _bufferingSubscription = widget.player.stream.buffering.listen((b) {
      if (mounted) setState(() => _buffering = b);
    });
    _volumeSubscription = widget.player.stream.volume.listen((v) {
      if (mounted) setState(() => _volume = v);
    });

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClock();
    });

    _startHideTimer();
  }

  void _updateClock() {
    if (mounted) {
      setState(() {
        _currentTimeStr = DateFormat('HH:mm').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _clockTimer.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _playingSubscription.cancel();
    _bufferingSubscription.cancel();
    _volumeSubscription.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _playing) {
        setState(() => _visible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _visible = !_visible;
      if (_visible) _startHideTimer();
    });
  }

  void _onUserInteraction() {
    if (!_visible) {
      setState(() => _visible = true);
    }
    _startHideTimer();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => _onUserInteraction(),
      child: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.translucent,
        child: Focus(
          onKeyEvent: (node, event) {
            _onUserInteraction();
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              AnimatedOpacity(
                opacity: _visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_visible,
                  child: Stack(
                    children: [
                      // Background Gradients
                      _buildGradients(),
                      // Top Bar
                      _buildTopBar(),
                      // Center Controls
                      _buildCenterControls(),
                      // Bottom Bar
                      _buildBottomBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradients() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _ControlButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _currentTimeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Center(
      child: _buffering
          ? const CircularProgressIndicator(color: Colors.white)
          : _ControlButton(
              icon: _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 64,
              onPressed: () => widget.player.playOrPause(),
            ),
    );
  }

  Widget _buildBottomBar() {
    final isDesktopOrWeb = kIsWeb ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seek Bar
              _buildSeekBar(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Spacer(),
                  if (isDesktopOrWeb) ...[
                    const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                    SizedBox(
                      width: 100,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 100,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                          onChanged: (v) => widget.player.setVolume(v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  _ControlButton(
                    icon: Icons.settings_rounded,
                    onPressed: () => EventBus().emit('toggle_video_settings', true),
                  ),
                  const SizedBox(width: 16),
                  _ControlButton(
                    icon: Icons.fullscreen_rounded,
                    onPressed: () async {
                      if (kIsWeb) {
                        // TODO: Implement web fullscreen
                        return;
                      }

                      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                        final isFullScreen = await windowManager.isFullScreen();
                        await windowManager.setFullScreen(!isFullScreen);
                      } else {
                        // Mobile fallback
                        final Orientation currentOrientation = MediaQuery.of(context).orientation;
                        if (currentOrientation == Orientation.portrait) {
                           await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                           await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
                        } else {
                           await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                           await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeekBar() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: AppThemes.primaryAccent,
        inactiveTrackColor: Colors.white24,
        thumbColor: AppThemes.primaryAccent,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayColor: AppThemes.primaryAccent.withOpacity(0.2),
      ),
      child: Slider(
        value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble()),
        min: 0,
        max: _duration.inMilliseconds.toDouble(),
        onChanged: (value) {
          widget.player.seek(Duration(milliseconds: value.toInt()));
        },
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableControlBuilder(
      onPressed: onPressed,
      builder: (context, state) {
        final isFocused = state.isFocused;
        return AnimatedScale(
          scale: isFocused ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              color: isFocused ? Colors.white.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
              border: isFocused ? Border.all(color: AppThemes.primaryAccent, width: 2) : null,
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: AppThemes.primaryAccent.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: isFocused ? AppThemes.primaryAccent : Colors.white,
              size: size,
            ),
          ),
        );
      },
    );
  }
}
