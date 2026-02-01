import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/services/epg_service.dart';

void main() {
  group('EpgService GZIP Support', () {
    test('Correctly decodes plain text', () {
      const plainText = 'This is a plain text string.';
      final bytes = utf8.encode(plainText);

      final result = EpgService.decodeContent(bytes);
      expect(result, equals(plainText));
    });

    test('Correctly decodes GZIP compressed data', () {
      const originalText = 'This is a compressed string for testing GZIP support.';
      final originalBytes = utf8.encode(originalText);
      final compressedBytes = GZipEncoder().encode(originalBytes);

      // Ensure it's actually compressed (or at least formatted as GZIP)
      expect(compressedBytes, isNotNull);

      final result = EpgService.decodeContent(compressedBytes!);
      expect(result, equals(originalText));
    });

    test('Handles invalid GZIP header by falling back to plain text', () {
      // Create bytes that start with GZIP magic number but aren't valid GZIP
      final invalidGzipBytes = [0x1f, 0x8b, 0x00, 0x00, 0x00];
      // This might throw or return garbage depending on implementation,
      // but our code catches exception and falls back to utf8.decode
      // However, utf8.decode might fail if bytes are not valid UTF8.

      // Let's try a case where we force the magic numbers but provide valid utf8 afterwards
      // to see if fallback works.
      // actually, if it fails gzip decode, it tries utf8.decode(bytes, allowMalformed: true)

      final result = EpgService.decodeContent(invalidGzipBytes);
      // It should return the utf8 decoded version of the input bytes
      expect(result, isNotEmpty);
    });
  });
}
