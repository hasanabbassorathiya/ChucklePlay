import 'package:lumio/utils/type_convertions.dart';

class Playlist {
  final String id;
  final String name;
  final PlaylistType type;
  final String? url;
  final String? username;
  final String? password;
  final String? epgUrl;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.username,
    this.password,
    this.epgUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'url': url,
      'username': username,
      'password': password,
      'epgUrl': epgUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: safeString(json['id']),
      name: safeString(json['name']),
      type: PlaylistType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => PlaylistType.m3u,
      ),
      url: safeString(json['url']),
      username: safeString(json['username']),
      password: safeString(json['password']),
      epgUrl: safeString(json['epgUrl']),
      createdAt:
          DateTime.tryParse(safeString(json['createdAt'])) ?? DateTime.now(),
    );
  }
}

enum PlaylistType { xtream, m3u }
