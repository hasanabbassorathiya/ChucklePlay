import 'package:lumio/services/firestore_service.dart';
import 'package:drift/drift.dart';
import 'package:lumio/database/database.dart';
import 'package:lumio/models/content_type.dart';
import 'package:lumio/models/watch_history.dart';
import 'package:lumio/services/service_locator.dart';

class WatchHistoryService {
  final _database = getIt<AppDatabase>();
  final FirestoreService _firestoreService = getIt<FirestoreService>();

  WatchHistoryService();

  Future<void> saveWatchHistory(WatchHistory history) async {
    await _database
        .into(_database.watchHistories)
        .insertOnConflictUpdate(history.toDriftCompanion());

    // Sync to cloud
    _firestoreService.syncWatchHistory(history);
  }

  Future<void> syncFromCloud() async {
    try {
      final cloudHistory = await _firestoreService.getWatchHistory();
      for (var history in cloudHistory) {
        await _database
            .into(_database.watchHistories)
            .insertOnConflictUpdate(history.toDriftCompanion());
      }
    } catch (e) {
      // debugPrint('Watch history sync error: $e');
    }
  }

  Future<WatchHistory?> getWatchHistory(
    String playlistId,
    String streamId,
  ) async {
    final query = _database.select(_database.watchHistories)
      ..where(
        (tbl) =>
            tbl.playlistId.equals(playlistId) & tbl.streamId.equals(streamId),
      );

    final result = await query.getSingleOrNull();
    return result != null ? WatchHistory.fromDrift(result) : null;
  }

  Future<List<WatchHistory>> getWatchHistoryByPlaylist(
    String playlistId,
  ) async {
    final query = _database.select(_database.watchHistories)
      ..where((tbl) => tbl.playlistId.equals(playlistId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastWatched)]);

    final results = await query.get();
    return results.map((data) => WatchHistory.fromDrift(data)).toList();
  }

  Future<List<WatchHistory>> getWatchHistoryByContentType(
    ContentType contentType, String playlistId
  ) async {
    final query = _database.select(_database.watchHistories)
      ..where((tbl) => tbl.contentType.equals(contentType.index) & tbl.playlistId.equals(playlistId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastWatched)]);

    final results = await query.get();
    return results.map((data) => WatchHistory.fromDrift(data)).toList();
  }

  Future<List<WatchHistory>> getRecentlyWatched(
    String playlistId, {
    int limit = 10,
  }) async {
    final query = _database.select(_database.watchHistories)
      ..where((tbl) => tbl.playlistId.equals(playlistId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastWatched)])
      ..limit(limit);

    final results = await query.get();
    return results.map((data) => WatchHistory.fromDrift(data)).toList();
  }

  Future<List<WatchHistory>> getContinueWatching(String playlistId) async {
    final query = _database.select(_database.watchHistories)
      ..where(
        (tbl) =>
            tbl.watchDuration.isNotNull() &
            tbl.totalDuration.isNotNull() &
            tbl.playlistId.equals(playlistId),
      )
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastWatched)]);

    final results = await query.get();
    return results.map((data) => WatchHistory.fromDrift(data)).toList();
  }

  Future<void> deleteWatchHistory(String playlistId, String streamId) async {
    await (_database.delete(_database.watchHistories)..where(
          (tbl) =>
              tbl.playlistId.equals(playlistId) & tbl.streamId.equals(streamId),
        ))
        .go();
  }

  Future<void> deletePlaylistHistory(String playlistId) async {
    await (_database.delete(
      _database.watchHistories,
    )..where((tbl) => tbl.playlistId.equals(playlistId))).go();
  }

  Future<void> clearAllHistory() async {
    await _database.delete(_database.watchHistories).go();
  }
}
