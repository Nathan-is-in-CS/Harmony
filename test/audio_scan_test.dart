import 'package:flutter_test/flutter_test.dart';
import 'package:harmony/src/platform_io_nonweb.dart';

void main() {
  group('audio scan helpers', () {
    test('recognizes supported audio file extensions', () {
      expect(isAudioFilePath('/storage/emulated/0/Music/song.mp3'), isTrue);
      expect(isAudioFilePath('/storage/emulated/0/Music/song.wav'), isTrue);
      expect(isAudioFilePath('/storage/emulated/0/Music/cover.jpg'), isFalse);
    });

    test('skips protected Android directories', () {
      expect(shouldSkipDirectory('/storage/emulated/0/Android'), isTrue);
      expect(shouldSkipDirectory('/sdcard/cache'), isTrue);
      expect(shouldSkipDirectory('/storage/emulated/0/Music'), isFalse);
    });

    test('deduplicates the same audio path across repeated scans', () async {
      final result = await deduplicateAudioPaths([
        '/storage/emulated/0/Music/song.mp3',
        '/storage/emulated/0/Music/song.mp3',
        '\\storage\\emulated\\0\\Music\\song.mp3',
      ]);

      expect(result, ['/storage/emulated/0/Music/song.mp3']);
    });
  });
}
