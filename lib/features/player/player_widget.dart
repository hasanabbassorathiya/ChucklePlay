import 'dart:async';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:lumio/models/playlist_content_model.dart';
import 'package:lumio/models/watch_history.dart';
import 'package:lumio/repositories/user_preferences.dart';
import 'package:lumio/services/app_state.dart';
import 'package:lumio/services/event_bus.dart';
import 'package:lumio/services/watch_history_service.dart';
import 'package:lumio/utils/get_playlist_type.dart';
import 'package:lumio/utils/subtitle_configuration.dart';
import 'package:lumio/features/player/widgets/video_settings_widget.dart';
import 'package:lumio/features/player/widgets/video_widget.dart';
import 'package:lumio/core/widgets/player_error_dialog.dart';
import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;

import 'package:screen_brightness/screen_brightness.dart';

import 'package:media_kit_video/media_kit_video.dart';
import '../../models/content_type.dart';
import '../../services/player_state.dart';
import '../../services/service_locator.dart';
import '../../utils/audio_handler.dart';
import '../../utils/player_error_handler.dart';

class PlayerWidget extends StatefulWidget {
  final ContentItem contentItem;
  final double? aspectRatio;
  final bool showControls;
  final bool showInfo;
  final VoidCallback? onFullscreen;
  final List<ContentItem>? queue;

  const PlayerWidget({
    super.key,
    required this.contentItem,
    this.aspectRatio,
    this.showControls = true,
    this.showInfo = false,
    this.onFullscreen,
    this.queue,
  });

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with WidgetsBindingObserver {
  final Map<ShortcutActivator, Intent> _shortcuts = {
    const SingleActivator(LogicalKeyboardKey.arrowUp): const _ChangeChannelIntent(1),
    const SingleActivator(LogicalKeyboardKey.arrowDown): const _ChangeChannelIntent(-1),
    const SingleActivator(LogicalKeyboardKey.arrowLeft): const _SeekIntent(Duration(seconds: -10)),
    const SingleActivator(LogicalKeyboardKey.arrowRight): const _SeekIntent(Duration(seconds: 10)),
    const SingleActivator(LogicalKeyboardKey.select): const _TogglePlayPauseIntent(),
    const SingleActivator(LogicalKeyboardKey.enter): const _TogglePlayPauseIntent(),
    const SingleActivator(LogicalKeyboardKey.gameButtonA): const _TogglePlayPauseIntent(),
    const SingleActivator(LogicalKeyboardKey.escape): const _BackIntent(),
    const SingleActivator(LogicalKeyboardKey.backspace): const _BackIntent(),
  };

  late final Map<Type, Action<Intent>> _actions = {
    _ChangeChannelIntent: CallbackAction<_ChangeChannelIntent>(
      onInvoke: (intent) => _changeChannel(intent.direction),
    ),
    _SeekIntent: CallbackAction<_SeekIntent>(
      onInvoke: (intent) => _player.seek(_player.state.position + intent.duration),
    ),
    _TogglePlayPauseIntent: CallbackAction<_TogglePlayPauseIntent>(
      onInvoke: (intent) => _player.playOrPause(),
    ),
    _BackIntent: CallbackAction<_BackIntent>(
      onInvoke: (intent) => _handleBackNavigation(),
    ),
  };

  void _handleBackNavigation() {
    if (_showChannelList) {
      setState(() => _showChannelList = false);
      return;
    }
    if (PlayerState.showVideoInfo) {
      EventBus().emit('toggle_video_info', false);
      return;
    }
    if (PlayerState.showVideoSettings) {
      EventBus().emit('toggle_video_settings', false);
      return;
    }
    Navigator.pop(context);
  }
  late StreamSubscription videoTrackSubscription;
  late StreamSubscription audioTrackSubscription;
  late StreamSubscription subtitleTrackSubscription;
  late StreamSubscription contentItemIndexChangedSubscription;
  late StreamSubscription _connectivitySubscription;
  StreamSubscription? _tracksSubscription;
  StreamSubscription? _trackSubscription;
  StreamSubscription? _volumeSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _playlistSubscription;
  StreamSubscription? _completedSubscription;
  StreamSubscription? _toggleChannelListSubscription;
  StreamSubscription? _toggleVideoInfoSubscription;
  StreamSubscription? _toggleVideoSettingsSubscription;

  late Player _player;
  VideoController? _videoController;
  late WatchHistoryService watchHistoryService;
  final MyAudioHandler _audioHandler = getIt<MyAudioHandler>();
  List<ContentItem>? _queue;
  late ContentItem contentItem;
  final PlayerErrorHandler _errorHandler = PlayerErrorHandler();

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  bool _wasDisconnected = false;
  bool _errorDialogShown = false;
  bool _isFirstCheck = true;
  int _currentItemIndex = 0;
  bool _showChannelList = false;
  bool _isLocked = false;
  Timer? _watchHistoryTimer;
  Duration? _pendingWatchDuration;
  Duration? _pendingTotalDuration;
  bool _isDisposed = false;

  // Mobile OSD state
  double? _osdValue;
  IconData? _osdIcon;
  String? _osdLabel;
  Timer? _osdTimer;

  void _showOSD({required IconData icon, double? value, String? label}) {
    if (!mounted) return;
    setState(() {
      _osdIcon = icon;
      _osdValue = value;
      _osdLabel = label;
    });
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _osdIcon = null;
          _osdValue = null;
          _osdLabel = null;
        });
      }
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    contentItem = widget.contentItem;
    _queue = widget.queue;

    // --- INSERTION 1: INITIAL CONTENT SET ---
    PlayerState.currentContent = widget.contentItem;
    PlayerState.queue = _queue;
    PlayerState.currentIndex = 0;
    // ----------------------------------------

    PlayerState.title = widget.contentItem.name;
    print('PlayerWidget: Initializing player for ${widget.contentItem.name}');
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, // 32MB buffer for smoother streaming
      ),
    );

    // Optimizations for streaming and rendering
    // media_kit 1.2.6+ handles hardware acceleration via VideoControllerConfiguration
    // Forced software rendering is now set in _videoController initialization below

    watchHistoryService = WatchHistoryService();

    super.initState();
    videoTrackSubscription = EventBus()
        .on<VideoTrack>('video_track_changed')
        .listen((VideoTrack data) async {
          _player.setVideoTrack(data);
          await UserPreferences.setVideoTrack(data.id);
        });

    audioTrackSubscription = EventBus()
        .on<AudioTrack>('audio_track_changed')
        .listen((AudioTrack data) async {
          _player.setAudioTrack(data);
          await UserPreferences.setAudioTrack(data.language ?? 'null');
        });

    subtitleTrackSubscription = EventBus()
        .on<SubtitleTrack>('subtitle_track_changed')
        .listen((SubtitleTrack data) async {
          _player.setSubtitleTrack(data);
          await UserPreferences.setSubtitleTrack(data.language ?? 'null');
        });

    _initializePlayer();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    WidgetsBinding.instance.removeObserver(this);

    // Cancel all subscriptions FIRST to prevent callbacks after disposal
    videoTrackSubscription.cancel();
    audioTrackSubscription.cancel();
    subtitleTrackSubscription.cancel();
    contentItemIndexChangedSubscription.cancel();
    _connectivitySubscription.cancel();
    _tracksSubscription?.cancel();
    _trackSubscription?.cancel();
    _volumeSubscription?.cancel();
    _positionSubscription?.cancel();
    _errorSubscription?.cancel();
    _playlistSubscription?.cancel();
    _completedSubscription?.cancel();
    _toggleChannelListSubscription?.cancel();
    _toggleVideoInfoSubscription?.cancel();
    _toggleVideoSettingsSubscription?.cancel();

    // Cancel timer and save watch history one last time before disposing
    _watchHistoryTimer?.cancel();
    if (_pendingWatchDuration != null) {
      // Use unawaited to save without blocking dispose
      _saveWatchHistory().catchError((e) {
        // Ignore errors during dispose
      });
    }

    // Stop audio handler before disposing player
    _audioHandler.setPlayer(null);
    _audioHandler.stop().catchError((e) {
      // Ignore errors during dispose
    });

    // Close and dispose player last
    try {
      // Try to pause the player first to stop playback
      // Access state carefully to avoid triggering callbacks
      try {
        final state = _player.state;
        if (state.playing) {
          _player.pause();
        }
      } catch (e) {
        // Ignore pause/state access errors - player might already be stopped or disposed
        // During hot restart, accessing state might fail
      }
      // Dispose the player
      // NOTE: During hot restart, native callbacks from libmpv might still fire
      // after the Dart isolate is destroyed, causing "Callback invoked after it has been deleted"
      // This is a known limitation of hot restart with FFI callbacks and cannot be fully prevented.
      // The error is harmless but will appear in logs during hot restart.
      _player.dispose();
    } catch (e) {
      // Player might already be disposed or in an invalid state, ignore error
      // This is expected during hot restart when the isolate is being destroyed
    }

    _errorHandler.reset();
    _errorDialogShown = false;
    super.dispose();
  }

  Future<void> _saveWatchHistory() async {
    final playlist = AppState.currentPlaylist;
    if (_pendingWatchDuration == null || !mounted || playlist == null) return;

    try {
      await watchHistoryService.saveWatchHistory(
        WatchHistory(
          playlistId: playlist.id,
          contentType: contentItem.contentType,
          streamId: isXtreamCode
              ? contentItem.id
              : contentItem.m3uItem?.id ?? contentItem.id,
          lastWatched: DateTime.now(),
          title: contentItem.name,
          imagePath: contentItem.imagePath,
          totalDuration: _pendingTotalDuration,
          watchDuration: _pendingWatchDuration,
          seriesId: contentItem.seriesStream?.seriesId,
        ),
      );
      _pendingWatchDuration = null;
      _pendingTotalDuration = null;
    } catch (e) {
      // Silently handle database errors to prevent crashes
      // The next save attempt will retry
      print('Error saving watch history: $e');
    }
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;

    final playlist = AppState.currentPlaylist;
    if (playlist == null) {
      debugPrint('PlayerWidget: AppState.currentPlaylist is null, cannot initialize player');
      if (mounted) Navigator.of(context).pop();
      return;
    }

    PlayerState.subtitleConfiguration = await getSubtitleConfiguration();

    PlayerState.backgroundPlay = await UserPreferences.getBackgroundPlay();
    _audioHandler.setPlayer(_player);
    print('PlayerWidget: Creating VideoController');
    _videoController = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        // DISABLE Hardware acceleration for debugging black screen issue
        // This forces Software rendering which is safer on emulators.
        enableHardwareAcceleration: false,
      ),
    );

    // Watch for size changes
    _videoController?.rect.addListener(() {
      print(
        'PlayerWidget: Video size changed: ${_videoController?.rect.value}',
      );
    });

    var watchHistory = await watchHistoryService.getWatchHistory(
      playlist.id,
      isXtreamCode ? contentItem.id : contentItem.m3uItem?.id ?? contentItem.id,
    );

    List<MediaItem> mediaItems = [];
    var currentItemIndex = 0;

    if (_queue != null) {
      for (int i = 0; i < _queue!.length; i++) {
        final item = _queue![i];
        final itemWatchHistory = await watchHistoryService.getWatchHistory(
          playlist.id,
          isXtreamCode ? item.id : item.m3uItem?.id ?? item.id,
        );

        mediaItems.add(
          MediaItem(
            id: item.id.toString(),
            title: item.name,
            artist: _getContentTypeDisplayName(),
            album: playlist.name,
            artUri: item.imagePath.isNotEmpty
                ? Uri.parse(item.imagePath)
                : null,
            playable: true,
            extras: {
              'url': item.url,
              'startPosition':
                  itemWatchHistory?.watchDuration?.inMilliseconds ?? 0,
            },
          ),
        );

        if (item.id == contentItem.id) {
          currentItemIndex = i;
          _currentItemIndex = i;

          if (contentItem.contentType == ContentType.liveStream) {
            currentItemIndex = 0;
            _currentItemIndex = 0;
            contentItem = item;

            mediaItems.add(
              MediaItem(
                id: item.id.toString(),
                title: item.name,
                artist: _getContentTypeDisplayName(),
                album: AppState.currentPlaylist?.name ?? '',
                artUri: item.imagePath.isNotEmpty
                    ? Uri.parse(item.imagePath)
                    : null,
                playable: true,
                extras: {'url': item.url, 'startPosition': 0},
              ),
            );

            EventBus().emit('player_content_item', item);
            EventBus().emit('player_content_item_index', i);
          }
        }
      }

      await _audioHandler.setQueue(mediaItems, initialIndex: currentItemIndex);

      if (contentItem.contentType != ContentType.liveStream) {
        var playlist = mediaItems.map((mediaItem) {
          final url = mediaItem.extras!['url'] as String;
          final startMs = mediaItem.extras!['startPosition'] as int;
          return Media(url, start: Duration(milliseconds: startMs));
        }).toList();

        await _player.open(
          Playlist(playlist, index: currentItemIndex),
          play: true,
        );
      } else {
        await _player.open(Media(contentItem.url));
      }
    } else {
      final mediaItem = MediaItem(
        id: contentItem.id.toString(),
        title: contentItem.name,
        artist: _getContentTypeDisplayName(),
        artUri: contentItem.imagePath.isNotEmpty
            ? Uri.parse(contentItem.imagePath)
            : null,
        extras: {
          'url': contentItem.url,
          'startPosition': watchHistory?.watchDuration?.inMilliseconds ?? 0,
        },
      );

      // if (contentItem.contentType == ContentType.liveStream) {
      //   liveStreamContentItem = contentItem;
      // }

      await _audioHandler.setQueue([mediaItem]);

      await _player.open(
        Playlist([
          Media(
            contentItem.url,
            start: watchHistory?.watchDuration ?? Duration(),
          ),
        ]),
        play: true,
      );
    }

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      if (_isDisposed || !mounted) return;

      try {
        bool hasConnection = results.any(
          (connectivity) =>
              connectivity == ConnectivityResult.mobile ||
              connectivity == ConnectivityResult.wifi ||
              connectivity == ConnectivityResult.ethernet,
        );

        if (_isFirstCheck) {
          final currentConnectivity = await Connectivity().checkConnectivity();
          hasConnection = currentConnectivity.any(
            (connectivity) =>
                connectivity == ConnectivityResult.mobile ||
                connectivity == ConnectivityResult.wifi ||
                connectivity == ConnectivityResult.ethernet,
          );
          _isFirstCheck = false;
        }

        if (hasConnection) {
          if (_wasDisconnected &&
              contentItem.contentType == ContentType.liveStream &&
              contentItem.url.isNotEmpty) {
            try {
              if (mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Online",
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }

              // TODO: Implement watch history duration for vod and series
              if (!_isDisposed) {
                await _player.open(Media(contentItem.url));
              }
            } catch (e) {
              // Ignore errors if player is disposed
              if (!_isDisposed) {
                print('Error opening media: $e');
              }
            }
          }
          _wasDisconnected = false;
        } else {
          _wasDisconnected = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "No Connection",
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Ignore errors if player is disposed
        if (!_isDisposed) rethrow;
      }
    });

    _tracksSubscription = _player.stream.tracks.listen((event) async {
      if (!mounted || _isDisposed) return;

      try {
        PlayerState.videos = event.video;
        PlayerState.audios = event.audio;
        PlayerState.subtitles = event.subtitle;

        EventBus().emit('player_tracks', event);

        await _player.setVideoTrack(
          VideoTrack(await UserPreferences.getVideoTrack(), null, null),
        );

        var selectedAudioLanguage = await UserPreferences.getAudioTrack();
        var possibleAudioTrack = event.audio.firstWhere(
          (x) => x.language == selectedAudioLanguage,
          orElse: AudioTrack.auto,
        );

        await _player.setAudioTrack(possibleAudioTrack);

        var selectedSubtitleLanguage = await UserPreferences.getSubtitleTrack();
        var possibleSubtitleLanguage = event.subtitle.firstWhere(
          (x) => x.language == selectedSubtitleLanguage,
          orElse: SubtitleTrack.auto,
        );

        await _player.setSubtitleTrack(possibleSubtitleLanguage);
      } catch (e) {
        // Ignore errors if player is disposed
        if (!_isDisposed) rethrow;
      }
    });

    _trackSubscription = _player.stream.track.listen((event) async {
      if (!mounted || _isDisposed) return;

      try {
        PlayerState.selectedVideo = _player.state.track.video;
        PlayerState.selectedAudio = _player.state.track.audio;
        PlayerState.selectedSubtitle = _player.state.track.subtitle;

        // Track değişikliğini bildir
        EventBus().emit('player_track_changed', null);

        var volume = await UserPreferences.getVolume();
        await _player.setVolume(volume);
      } catch (e) {
        // Ignore errors if player is disposed
        if (!_isDisposed) rethrow;
      }
    });

    _volumeSubscription = _player.stream.volume.listen((event) async {
      await UserPreferences.setVolume(event);
    });

    _positionSubscription = _player.stream.position.listen((position) {
      if (_isDisposed || !mounted) return;

      try {
        // Debounce: Save watch history every 5 seconds instead of on every position update
        _pendingWatchDuration = position;
        _pendingTotalDuration = _player.state.duration;

        _watchHistoryTimer?.cancel();
        _watchHistoryTimer = Timer(const Duration(seconds: 5), () {
          if (!_isDisposed && mounted) {
            _saveWatchHistory();
          }
        });
      } catch (e) {
        // Ignore errors if player is disposed
        if (!_isDisposed) rethrow;
      }
    });

    _errorSubscription = _player.stream.error.listen((error) async {
      if (_isDisposed || !mounted) return;

      try {
        print('PLAYER ERROR -> $error');

        // Update error state for UI
        if (mounted) {
          setState(() {
            hasError = true;
            errorMessage = error;
          });
        }

        // Show error dialog if not already shown
        if (mounted && !_errorDialogShown) {
          _errorDialogShown = true;

          // For auto-retryable errors, try to handle them first
          if (error.contains('Failed to open') ||
              error.contains('No video') ||
              error.contains('EGL') ||
              error.contains('video')) {
            _errorHandler.handleError(
              error,
              () async {
                if (!_isDisposed &&
                    mounted &&
                    contentItem.contentType == ContentType.liveStream) {
                  try {
                    await _player.open(Media(contentItem.url));
                    if (mounted) {
                      setState(() {
                        hasError = false;
                        errorMessage = '';
                        _errorDialogShown = false;
                      });
                    }
                  } catch (e) {
                    print('Error retrying playback: $e');
                    // If retry fails, show dialog
                    if (mounted) {
                      _showErrorDialog(error);
                    }
                  }
                } else {
                  // For non-live streams, show dialog immediately
                  if (mounted) {
                    _showErrorDialog(error);
                  }
                }
              },
              (errorMessage) {
                // Show error dialog when auto-retry fails
                if (mounted) {
                  _showErrorDialog(errorMessage);
                }
              },
            );
          } else {
            // For other errors, show dialog immediately
            _showErrorDialog(error);
          }
        }
      } catch (e) {
        // Ignore errors if player is disposed
        if (!_isDisposed) rethrow;
      }
    });

    _playlistSubscription = _player.stream.playlist.listen((playlist) {
      if (!mounted || _isDisposed) return;

      try {
        if (contentItem.contentType == ContentType.liveStream) {
          return;
        }

        _currentItemIndex = playlist.index;
        currentItemIndex = _currentItemIndex;
        contentItem = _queue?[playlist.index] ?? widget.contentItem;

        // --- INSERTION 2: QUEUE CHANGE SETTER ---
        PlayerState.currentContent = contentItem;
        PlayerState.currentIndex = _currentItemIndex;
        // ----------------------------------------

        PlayerState.title = contentItem.name;
        EventBus().emit('player_content_item', contentItem);
        EventBus().emit('player_content_item_index', playlist.index);

        // Kanal listesi açıksa güncelle
        if (_showChannelList && mounted) {
          setState(() {});
        }
      } catch (e) {
        // Ignore errors if player is disposed
        if (!_isDisposed) rethrow;
      }
    });

    _completedSubscription = _player.stream.completed.listen((playlist) async {
      if (_isDisposed || !mounted) return;

      try {
        if (contentItem.contentType == ContentType.liveStream) {
          await _player.open(Media(contentItem.url));
        }
      } catch (e) {
        // Ignore errors if player is disposed
        if (!_isDisposed) rethrow;
      }
    });

    contentItemIndexChangedSubscription = EventBus()
        .on<int>('player_content_item_index_changed')
        .listen((int index) async {
          if (_isDisposed || !mounted) return;

          try {
            if (contentItem.contentType == ContentType.liveStream) {
              // Queue'yu PlayerState'ten al (kategori değiştiğinde güncellenmiş olabilir)
              final updatedQueue = PlayerState.queue ?? _queue;
              if (updatedQueue == null || index >= updatedQueue.length) return;

              final item = updatedQueue[index];
              contentItem = item;
              _queue = updatedQueue; // Queue'yu güncelle

              // --- INSERTION 3: EXTERNAL CHANGE SETTER ---
              PlayerState.currentContent = contentItem;
              PlayerState.currentIndex = index;
              PlayerState.title = item.name;
              _currentItemIndex = index;
              // -------------------------------------------

              if (!_isDisposed) {
                await _player.open(Playlist([Media(item.url)]), play: true);
              }
              EventBus().emit('player_content_item', item);
              EventBus().emit('player_content_item_index', index);
              _errorHandler.reset();

              // Kanal listesi açıksa güncelle
              if (_showChannelList && mounted) {
                setState(() {});
              }
            } else {
              if (!_isDisposed) {
                _player.jump(index);
              }
            }
          } catch (e) {
            // Ignore errors if player is disposed
            if (!_isDisposed) rethrow;
          }
        });

    // Kanal listesi göster/gizle event'i
    _toggleChannelListSubscription = EventBus()
        .on<bool>('toggle_channel_list')
        .listen((bool show) {
          if (mounted) {
            setState(() {
              _showChannelList = show;
              PlayerState.showChannelList = show;
            });
          }
        });

    // Video bilgisi göster/gizle event'i
    _toggleVideoInfoSubscription = EventBus()
        .on<bool>('toggle_video_info')
        .listen((bool show) {
          if (mounted) {
            setState(() {
              PlayerState.showVideoInfo = show;
            });
          }
        });

    // Video ayarları göster/gizle event'i
    _toggleVideoSettingsSubscription = EventBus()
        .on<bool>('toggle_video_settings')
        .listen((bool show) {
          if (mounted) {
            setState(() {
              PlayerState.showVideoSettings = show;
            });
          }
        });

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_isDisposed || !mounted) return;

    switch (state) {
      case AppLifecycleState.detached:
        // Don't dispose here - let the dispose() method handle it
        // Just pause playback if needed
        try {
          if (_player.state.playing) {
            await _player.pause();
          }
        } catch (e) {
          // Player might already be disposed, ignore error
        }
        break;
      default:
        break;
    }
  }

  void _changeChannel(int direction) {
    if (_queue == null || _queue!.length <= 1) return;

    final newIndex = _currentItemIndex + direction;
    if (newIndex < 0 || newIndex >= _queue!.length) return;

    EventBus().emit('player_content_item_index_changed', newIndex);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _showErrorDialog(String error) {
    if (!mounted || _isDisposed) return;

    PlayerErrorDialog.show(
      context,
      errorMessage: error,
      onRetry: () {
        _errorDialogShown = false;
        setState(() {
          hasError = false;
          errorMessage = '';
        });
        // Retry playback
        if (contentItem.url.isNotEmpty) {
          _player
              .open(Media(contentItem.url))
              .then((_) {
                if (mounted) {
                  setState(() {
                    hasError = false;
                    errorMessage = '';
                  });
                }
              })
              .catchError((e) {
                print('Error retrying: $e');
                if (mounted) {
                  _errorDialogShown = false;
                  _showErrorDialog(e.toString());
                }
              });
        }
      },
      onDismiss: () {
        _errorDialogShown = false;
        setState(() {
          hasError = false;
          errorMessage = '';
        });
      },
    );
  }

  Widget _buildChannelListOverlay(BuildContext context) {
    final items = _queue!;
    final currentContent = PlayerState.currentContent;
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = (screenWidth / 3).clamp(280.0, 420.0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mevcut index'i bul
    int selectedIndex = _currentItemIndex;
    if (currentContent != null && items.isNotEmpty) {
      final foundIndex = items.indexWhere(
        (item) => item.id == currentContent.id,
      );
      if (foundIndex != -1) {
        selectedIndex = foundIndex;
      }
    }

    String overlayTitle = 'Kanal Seç';
    if (currentContent?.contentType == ContentType.vod) {
      overlayTitle = 'Filmler';
    } else if (currentContent?.contentType == ContentType.series) {
      overlayTitle = 'Bölümler';
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showChannelList = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {}, // Panel içine tıklanınca kapanmasın
              child: Container(
                width: panelWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Modern Header with gradient
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.15),
                            theme.colorScheme.primary.withOpacity(0.05),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.tv_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  overlayTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${selectedIndex + 1} / ${items.length}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.colorScheme.onSurface,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () {
                              setState(() {
                                _showChannelList = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // Channel list with modern styling
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = index == selectedIndex;

                          return _buildChannelListItem(
                            context,
                            item,
                            index,
                            isSelected,
                          );
                        },
                      ),
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

  Widget _buildChannelListItem(
    BuildContext context,
    ContentItem item,
    int index,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return FocusableControlBuilder(
      onPressed: () {
        EventBus().emit('player_content_item_index_changed', index);
      },
      builder: (context, state) {
        final isFocused = state.isFocused;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFocused
                ? primaryColor.withOpacity(0.2)
                : isSelected
                    ? primaryColor.withOpacity(0.15)
                    : isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: isFocused
                ? Border.all(color: const Color(0xFFE50914), width: 2)
                : isSelected
                    ? Border.all(color: primaryColor, width: 2)
                    : Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        width: 1,
                      ),
            boxShadow: (isFocused || isSelected)
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Thumbnail with modern styling
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isFocused || isSelected)
                        ? primaryColor
                        : isDark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                    width: (isFocused || isSelected) ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: item.imagePath.isNotEmpty
                      ? Image.network(
                          item.imagePath,
                          width: 56,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 56,
                              height: 40,
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              child: Icon(
                                Icons.image_rounded,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                                size: 20,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 56,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          child: Icon(
                            Icons.video_library_rounded,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Title and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: (isFocused || isSelected)
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _getContentTypeIcon(item.contentType),
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getContentTypeDisplayNameForItem(item.contentType),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getContentTypeIcon(ContentType contentType) {
    switch (contentType) {
      case ContentType.liveStream:
        return Icons.live_tv;
      case ContentType.vod:
        return Icons.movie;
      case ContentType.series:
        return Icons.tv;
    }
  }

  String _getContentTypeDisplayNameForItem(ContentType contentType) {
    switch (contentType) {
      case ContentType.liveStream:
        return 'Canlı Yayın';
      case ContentType.vod:
        return 'Film';
      case ContentType.series:
        return 'Dizi';
    }
  }

  String _getContentTypeDisplayName() {
    switch (widget.contentItem.contentType) {
      case ContentType.liveStream:
        return 'Canlı Yayın';
      case ContentType.vod:
        return 'Film';
      case ContentType.series:
        return 'Dizi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final isLandscape = screenSize.width > screenSize.height;
    final isMobile =
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;

    // Series ve LiveStream için tam ekran modu
    final isSeries = widget.contentItem.contentType == ContentType.series;
    final isLiveStream =
        widget.contentItem.contentType == ContentType.liveStream;
    final isVod = widget.contentItem.contentType == ContentType.vod;
    final isFullScreen = isSeries || isLiveStream || isVod;

    double calculateAspectRatio() {
      if (widget.aspectRatio != null) return widget.aspectRatio!;

      if (isTablet) {
        return isLandscape ? 21 / 9 : 16 / 9;
      }
      return 16 / 9;
    }

    double? calculateMaxHeight() {
      if (isTablet) {
        if (isLandscape) {
          return screenSize.height * 0.6;
        } else {
          return screenSize.height * 0.4;
        }
      }
      return null;
    }

    Widget playerWidget;

    if (isFullScreen) {
      // Series ve LiveStream için tam ekran
      // On mobile, use actual screen dimensions to ensure proper sizing
      if (isMobile) {
        playerWidget = SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: isLoading
              ? Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : _buildPlayerContent(),
        );
      } else {
        // For desktop/tablet, use double.infinity
        playerWidget = SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: isLoading
              ? Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : _buildPlayerContent(),
        );
      }
    } else {
      // Diğer içerikler için aspect ratio kullan
      playerWidget = AspectRatio(
        aspectRatio: calculateAspectRatio(),
        child: isLoading
            ? Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : _buildPlayerContent(),
      );

      if (isTablet) {
        final maxHeight = calculateMaxHeight();
        if (maxHeight != null) {
          playerWidget = ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: playerWidget,
          );
        }
      }
    }

    return Container(
      color: Colors.black,
      child: isFullScreen ? playerWidget : Column(children: [playerWidget]),
    );
  }

  Widget _buildPlayerContent() {
    // Check if video controller is initialized
    if (_videoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Error state is now handled by dialog, but show a minimal loading/error indicator
    if (hasError && !_errorDialogShown) {
      // Show a subtle error indicator while dialog is being prepared
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Preparing error information...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isMobile =
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;

    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _actions,
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            onDoubleTapDown: isMobile ? (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < screenWidth / 2) {
                _player.seek(_player.state.position - const Duration(seconds: 10));
              } else {
                _player.seek(_player.state.position + const Duration(seconds: 10));
              }
            } : null,
            onHorizontalDragUpdate: isMobile && !_isLocked ? (details) {
              final delta = details.primaryDelta! / 200;
              final newPosition = _player.state.position + Duration(seconds: (delta * 60).round());
              _player.seek(newPosition);

              _showOSD(
                icon: delta > 0 ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
                label: _formatDuration(newPosition),
              );
            } : null,
            onVerticalDragUpdate: isMobile && !_isLocked ? (details) async {
              final screenWidth = MediaQuery.of(context).size.width;
              final delta = -details.primaryDelta! / 100;
              if (details.globalPosition.dx < screenWidth / 2) {
                // Brightness
                try {
                  double currentBrightness = await ScreenBrightness().current;
                  double newBrightness = (currentBrightness + delta).clamp(0.0, 1.0);
                  await ScreenBrightness().setScreenBrightness(newBrightness);
                  _showOSD(
                    icon: newBrightness > 0.5 ? Icons.brightness_high_rounded : Icons.brightness_low_rounded,
                    value: newBrightness,
                    label: '${(newBrightness * 100).round()}%',
                  );
                } catch (e) {
                  print('Error setting brightness: $e');
                }
              } else {
                final newVolume = (_player.state.volume + delta * 100).clamp(0.0, 100.0);
                _player.setVolume(newVolume);
                _showOSD(
                  icon: newVolume > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  value: newVolume / 100,
                  label: '${newVolume.round()}%',
                );
              }
            } : null,
            onVerticalDragEnd: (details) {
              if (isMobile) return; // Prevent conflict with brightness/volume
              if (_queue == null || _queue!.length <= 1) return;

              // Yukarı swipe - sonraki kanal
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -500) {
                _changeChannel(1);
              }
              // Aşağı swipe - önceki kanal
              else if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 500) {
                _changeChannel(-1);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video widget - let it fill the available space
                Positioned.fill(
                  child: getVideo(
                    context,
                    _videoController!,
                    PlayerState.subtitleConfiguration,
                    onBack: _handleBackNavigation,
                  ),
                ),

                if (widget.onFullscreen != null &&
                    (Theme.of(context).platform == TargetPlatform.macOS ||
                        Theme.of(context).platform == TargetPlatform.windows ||
                        Theme.of(context).platform == TargetPlatform.linux))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: widget.onFullscreen,
                      icon: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 24,
                      ),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    ),
                  ),

                // Kanal listesi overlay - normal mod için
                if (_showChannelList && _queue != null && _queue!.length > 1)
                  _buildChannelListOverlay(context),

                // Video Settings Overlay
                if (PlayerState.showVideoSettings)
                  VideoSettingsWidget(
                    onClose: () {
                      EventBus().emit('toggle_video_settings', false);
                    },
                  ),

                // OSD Overlay
                if (_osdIcon != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_osdIcon, color: Colors.white, size: 48),
                          if (_osdValue != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 150,
                              child: LinearProgressIndicator(
                                value: _osdValue,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(Color(0xFFE50914)),
                              ),
                            ),
                          ],
                          if (_osdLabel != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _osdLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // Mobile Lock Button
                if (isMobile)
                  Positioned(
                    left: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          setState(() => _isLocked = !_isLocked);
                          _showOSD(
                            icon: _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                            label: _isLocked ? 'Controls Locked' : 'Controls Unlocked',
                          );
                        },
                        icon: Icon(
                          _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black26,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangeChannelIntent extends Intent {
  final int direction;
  const _ChangeChannelIntent(this.direction);
}

class _SeekIntent extends Intent {
  final Duration duration;
  const _SeekIntent(this.duration);
}

class _TogglePlayPauseIntent extends Intent {
  const _TogglePlayPauseIntent();
}

class _BackIntent extends Intent {
  const _BackIntent();
}
