import 'package:drift/drift.dart';
import '../database/database.dart';

class EpgChannel {
  final String id;
  final String playlistId;
  final String? displayName;
  final String? icon;

  EpgChannel({
    required this.id,
    required this.playlistId,
    this.displayName,
    this.icon,
  });

  factory EpgChannel.fromDrift(EpgChannelsData data) {
    return EpgChannel(
      id: data.id,
      playlistId: data.playlistId,
      displayName: data.displayName,
      icon: data.icon,
    );
  }

  EpgChannelsCompanion toCompanion() {
    return EpgChannelsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      displayName: Value(displayName),
      icon: Value(icon),
    );
  }

  @override
  String toString() {
    return 'EpgChannel(id: $id, displayName: $displayName)';
  }
}
