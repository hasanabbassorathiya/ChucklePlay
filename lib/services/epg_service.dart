import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:lumio/database/database.dart';
import 'package:lumio/models/epg_channel.dart';
import 'package:lumio/models/epg_program.dart';
import 'package:lumio/services/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class EpgService {
  static final _database = getIt<AppDatabase>();

  /// Fetches EPG from a URL (supports gzip) or local file path
  /// and updates the database for the given [playlistId].
  static Future<void> updateEpg(String playlistId, String urlOrPath) async {
    debugPrint('Starting EPG update for playlist: $playlistId');

    // 1. Clear existing EPG data for this playlist
    await _database.deleteEpgData(playlistId);

    // 2. Fetch/Read content
    String xmlContent;
    try {
      if (urlOrPath.startsWith('http')) {
        xmlContent = await _fetchUrl(urlOrPath);
      } else {
        final file = File(urlOrPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          xmlContent = decodeContent(bytes);
        } else {
          debugPrint('EPG file does not exist: $urlOrPath');
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading EPG content: $e');
      return;
    }

    if (xmlContent.isEmpty) {
      debugPrint('EPG content is empty');
      return;
    }

    // 3. Parse and Insert (Run in isolate if needed, but for now doing it here)
    // For very large files, we should use XmlEventDecoder/Stream,
    // but standard DOM parsing is easier to implement first.
    try {
      await _parseAndInsertXml(playlistId, xmlContent);
      debugPrint('EPG update completed successfully');
    } catch (e) {
      debugPrint('Error parsing EPG XML: $e');
      rethrow;
    }
  }

  static Future<String> _fetchUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return decodeContent(response.bodyBytes);
      } else {
        throw Exception('Failed to load EPG: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch EPG: $e');
    }
  }

  @visibleForTesting
  static String decodeContent(List<int> bytes) {
    // Check for GZIP magic number (0x1f, 0x8b)
    if (bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      try {
        final decoded = GZipDecoder().decodeBytes(bytes);
        return utf8.decode(decoded);
      } catch (e) {
        debugPrint('Error decoding GZIP content: $e');
        // Try falling back to plain text
        return utf8.decode(bytes, allowMalformed: true);
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static Future<void> _parseAndInsertXml(String playlistId, String xmlContent) async {
    final document = XmlDocument.parse(xmlContent);
    final tvElement = document.findAllElements('tv').firstOrNull;

    if (tvElement == null) return;

    final List<EpgChannel> channels = [];
    final List<EpgProgram> programs = [];

    // Parse Channels
    for (final node in tvElement.findAllElements('channel')) {
      final id = node.getAttribute('id');
      if (id != null) {
        final displayName = node.findAllElements('display-name').firstOrNull?.innerText;
        final icon = node.findAllElements('icon').firstOrNull?.getAttribute('src');

        channels.add(EpgChannel(
          id: id,
          playlistId: playlistId,
          displayName: displayName,
          icon: icon,
        ));
      }
    }

    // Parse Programs
    for (final node in tvElement.findAllElements('programme')) {
      final startStr = node.getAttribute('start');
      final stopStr = node.getAttribute('stop');
      final channelId = node.getAttribute('channel');

      if (startStr != null && stopStr != null && channelId != null) {
        final title = node.findAllElements('title').firstOrNull?.innerText ?? 'No Title';
        final desc = node.findAllElements('desc').firstOrNull?.innerText;
        final category = node.findAllElements('category').firstOrNull?.innerText;

        final start = _parseXmltvDate(startStr);
        final stop = _parseXmltvDate(stopStr);

        if (start != null && stop != null) {
          programs.add(EpgProgram(
            channelId: channelId,
            playlistId: playlistId,
            start: start,
            stop: stop,
            title: title,
            desc: desc,
            category: category,
          ));
        }
      }
    }

    // Bulk Insert
    if (channels.isNotEmpty) {
      await _database.insertEpgChannels(channels);
      debugPrint('Inserted ${channels.length} channels');
    }

    if (programs.isNotEmpty) {
      // Chunk inserts to avoid too many variables in a single SQL statement
      const chunkSize = 500;
      for (var i = 0; i < programs.length; i += chunkSize) {
        final end = (i + chunkSize < programs.length) ? i + chunkSize : programs.length;
        await _database.insertEpgPrograms(programs.sublist(i, end));
      }
      debugPrint('Inserted ${programs.length} programs');
    }
  }

  /// Parses dates in format "YYYYMMDDhhmmss ±hhmm"
  static DateTime? _parseXmltvDate(String dateStr) {
    // Basic length check: YYYYMMDDhhmmss (14 chars) + optional timezone
    if (dateStr.length < 14) return null;

    try {
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      final hour = int.parse(dateStr.substring(8, 10));
      final minute = int.parse(dateStr.substring(10, 12));
      final second = int.parse(dateStr.substring(12, 14));

      DateTime dt = DateTime.utc(year, month, day, hour, minute, second);

      // Handle timezone offset if present
      // Format usually: +0000 or -0500
      if (dateStr.length >= 19) { // 14 + space + 5 char tz
        final tzPart = dateStr.substring(14).trim(); // "+0000"
        if (tzPart.length == 5) {
          final sign = tzPart.substring(0, 1);
          final tzHour = int.parse(tzPart.substring(1, 3));
          final tzMinute = int.parse(tzPart.substring(3, 5));

          final offsetDuration = Duration(hours: tzHour, minutes: tzMinute);

          if (sign == '+') {
            dt = dt.subtract(offsetDuration); // Convert to UTC
          } else if (sign == '-') {
            dt = dt.add(offsetDuration); // Convert to UTC
          }
        }
      }

      // Store as local time for easier display, or keep UTC?
      // Database usually stores UTC. We converted to UTC above.
      return dt;
    } catch (e) {
      debugPrint('Error parsing date: $dateStr - $e');
      return null;
    }
  }

  static Future<List<EpgProgram>> getPrograms(String channelId, String playlistId) async {
    return _database.getEpgProgramsForChannel(channelId, playlistId);
  }

  static Future<EpgProgram?> getCurrentProgram(String channelId, String playlistId) async {
    return _database.getCurrentProgram(channelId, playlistId);
  }
}
