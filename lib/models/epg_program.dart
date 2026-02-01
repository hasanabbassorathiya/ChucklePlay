import 'package:drift/drift.dart';
import '../database/database.dart';

class EpgProgram {
  final String channelId;
  final String playlistId;
  final DateTime start;
  final DateTime stop;
  final String title;
  final String? desc;
  final String? category;

  EpgProgram({
    required this.channelId,
    required this.playlistId,
    required this.start,
    required this.stop,
    required this.title,
    this.desc,
    this.category,
  });

  factory EpgProgram.fromDrift(EpgProgramsData data) {
    return EpgProgram(
      channelId: data.channelId,
      playlistId: data.playlistId,
      start: data.start,
      stop: data.stop,
      title: data.title,
      desc: data.desc,
      category: data.category,
    );
  }

  EpgProgramsCompanion toCompanion() {
    return EpgProgramsCompanion(
      channelId: Value(channelId),
      playlistId: Value(playlistId),
      start: Value(start),
      stop: Value(stop),
      title: Value(title),
      desc: Value(desc),
      category: Value(category),
    );
  }

  @override
  String toString() {
    return 'EpgProgram(title: $title, start: $start, stop: $stop)';
  }
}
