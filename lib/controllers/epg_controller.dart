import 'package:lumio/database/database.dart';

import 'package:lumio/models/epg_channel.dart';
import 'package:lumio/models/epg_program.dart';
import 'package:lumio/services/epg_service.dart';
import 'package:lumio/services/service_locator.dart';
import 'package:flutter/foundation.dart';

class EpgController extends ChangeNotifier {
  final _database = getIt<AppDatabase>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<EpgChannel> _channels = [];
  List<EpgChannel> get channels => _channels;

  // Map of ChannelID -> List<Program>
  final Map<String, List<EpgProgram>> _programs = {};
  Map<String, List<EpgProgram>> get programs => _programs;

  Future<void> loadEpgData(String playlistId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get all EPG channels for this playlist
      final driftChannels = await (_database.select(
        _database.epgChannels,
      )..where((t) => t.playlistId.equals(playlistId))).get();

      _channels = driftChannels.map((c) => EpgChannel.fromDrift(c)).toList();

      // 2. Load programs for the visible time window (e.g., now +/- 2 hours)
      // For simplicity in this MVP, let's load programs for the current day for all loaded channels
      // In a real app with thousands of channels, we'd only load for visible channels.

      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 2));
      final end = now.add(const Duration(hours: 4));

      for (var channel in _channels) {
        final channelPrograms = await _database.getEpgProgramsForChannel(
          channel.id,
          playlistId,
          startTime: start,
          endTime: end,
        );
        _programs[channel.id] = channelPrograms;
      }
    } catch (e) {
      debugPrint('Error loading EPG data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get current program for a channel
  EpgProgram? getCurrentProgram(String channelId) {
    final channelPrograms = _programs[channelId];
    if (channelPrograms == null) return null;

    final now = DateTime.now();
    try {
      return channelPrograms.firstWhere(
        (p) => p.start.isBefore(now) && p.stop.isAfter(now),
      );
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> findStreamForChannel(
    String channelId,
    String playlistId,
  ) async {
    // Try to find M3uItem first
    debugPrint(
      'EpgController: Finding stream for channel $channelId in playlist $playlistId',
    );
    final m3uItems =
        await (_database.select(_database.m3uItems)
              ..where((t) => t.playlistId.equals(playlistId))
              ..where((t) => t.tvgId.equals(channelId))
              ..limit(1))
            .get();

    if (m3uItems.isNotEmpty) {
      return m3uItems.first;
    }

    // Try LiveStream (Xtream Codes)
    final liveStreams =
        await (_database.select(_database.liveStreams)
              ..where((t) => t.playlistId.equals(playlistId))
              ..where((t) => t.epgChannelId.equals(channelId))
              ..limit(1))
            .get();

    if (liveStreams.isNotEmpty) {
      return liveStreams.first;
    }

    return null;
  }
}
