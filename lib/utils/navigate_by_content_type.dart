import 'package:lumio/features/player/m3u_series_screen.dart';
import 'package:lumio/utils/get_playlist_type.dart';
import 'package:flutter/material.dart';
import 'package:lumio/models/content_type.dart';
import 'package:lumio/models/playlist_content_model.dart';
import 'package:lumio/features/player/live_stream_screen.dart';
import 'package:lumio/features/player/m3u_player_screen.dart';
import 'package:lumio/features/player/movie_screen.dart';
import 'package:lumio/features/player/series_screen.dart';

void navigateByContentType(BuildContext context, ContentItem content) {
  if (isM3u &&
      ((content.m3uItem != null && content.m3uItem!.groupTitle == null) ||
          content.contentType == ContentType.series)) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => M3uPlayerScreen(
          contentItem: ContentItem(
            content.m3uItem!.id,
            content.m3uItem!.name ?? '',
            content.m3uItem!.tvgLogo ?? '',
            content.m3uItem!.contentType,
            m3uItem: content.m3uItem!,
          ),
        ),
      ),
    );

    return;
  }

  switch (content.contentType) {
    case ContentType.liveStream:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveStreamScreen(content: content),
        ),
      );
      break;
    case ContentType.vod:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MovieScreen(contentItem: content),
        ),
      );
      break;
    case ContentType.series:
      if (isXtreamCode) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeriesScreen(contentItem: content),
          ),
        );
      } else if (isM3u) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => M3uSeriesScreen(contentItem: content),
          ),
        );
      }
      break;
  }
}
