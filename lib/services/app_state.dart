import 'package:lumio/models/m3u_item.dart';
import 'package:lumio/models/playlist_model.dart';
import 'package:lumio/repositories/iptv_repository.dart';
import 'package:lumio/repositories/m3u_repository.dart';

abstract class AppState {
  static Playlist? currentPlaylist;
  static IptvRepository? xtreamCodeRepository;
  static M3uRepository? m3uRepository;
  static List<M3uItem>? m3uItems;
}
