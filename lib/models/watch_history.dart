import 'package:drift/drift.dart';
import 'package:lumio/database/database.dart';
import 'package:lumio/models/content_type.dart';

class WatchHistory {
  late String playlistId;
  late ContentType contentType;
  late String streamId;
  late String? seriesId;
  late Duration? watchDuration;
  late Duration? totalDuration;
  late DateTime lastWatched;
  late String? imagePath;
  late String title;

  WatchHistory({
    required this.playlistId,
    required this.contentType,
    required this.streamId,
    this.seriesId,
    this.watchDuration,
    this.totalDuration,
    required this.lastWatched,
    this.imagePath,
    required this.title,
  });

  WatchHistory.fromDrift(WatchHistoriesData data) {
    playlistId = data.playlistId;
    contentType = data.contentType;
    streamId = data.streamId;
    seriesId = data.seriesId;
    watchDuration = data.watchDuration != null
        ? Duration(milliseconds: data.watchDuration!)
        : null;
    totalDuration = data.totalDuration != null
        ? Duration(milliseconds: data.totalDuration!)
        : null;
    lastWatched = data.lastWatched;
    imagePath = data.imagePath;
    title = data.title;
  }

  WatchHistoriesCompanion toDriftCompanion() {
    return WatchHistoriesCompanion(
      playlistId: Value(playlistId),
      contentType: Value(contentType),
      streamId: Value(streamId),
      seriesId: Value(seriesId),
      watchDuration: Value(watchDuration?.inMilliseconds),
      totalDuration: Value(totalDuration?.inMilliseconds),
      lastWatched: Value(lastWatched),
      imagePath: Value(imagePath),
      title: Value(title),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlistId': playlistId,
      'contentType': contentType.index,
      'streamId': streamId,
      'seriesId': seriesId,
      'watchDuration': watchDuration?.inMilliseconds,
      'totalDuration': totalDuration?.inMilliseconds,
      'lastWatched': lastWatched.toIso8601String(),
      'imagePath': imagePath,
      'title': title,
    };
  }

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      playlistId: json['playlistId'],
      contentType: ContentType.values[json['contentType']],
      streamId: json['streamId'],
      seriesId: json['seriesId'],
      watchDuration: json['watchDuration'] != null
          ? Duration(milliseconds: json['watchDuration'])
          : null,
      totalDuration: json['totalDuration'] != null
          ? Duration(milliseconds: json['totalDuration'])
          : null,
      lastWatched: DateTime.parse(json['lastWatched']),
      imagePath: json['imagePath'],
      title: json['title'],
    );
  }
}
