import 'package:flutter_test/flutter_test.dart';
import 'package:harmony/src/platform_io_nonweb.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

Directory? _hiveTestDir;

Future<void> _ensureHiveBoxes() async {
  _hiveTestDir ??= await Directory.systemTemp.createTemp('harmony_hive_test_');
  Hive.init(_hiveTestDir!.path);
  if (!Hive.isBoxOpen('tracks_box')) await Hive.openBox('tracks_box');
  if (!Hive.isBoxOpen('audio_blobs')) await Hive.openBox('audio_blobs');
  if (!Hive.isBoxOpen('settings_box')) await Hive.openBox('settings_box');
  if (!Hive.isBoxOpen('lyrics_box')) await Hive.openBox('lyrics_box');
}

Future<void> _cleanupHive() async {
  await Hive.close();
  if (_hiveTestDir != null && _hiveTestDir!.existsSync()) {
    try {
      _hiveTestDir!.deleteSync(recursive: true);
    } catch (_) {}
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('harmony_pathprov_');
    final binding = TestDefaultBinaryMessengerBinding.instance;
    final pathProvChannel = const MethodChannel('plugins.flutter.io/path_provider');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvChannel, (call) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
        case 'getDownloadsDirectory':
        case 'getExternalStorageDirectory':
        case 'getTemporaryDirectory':
          return tempDir.path;
      }
      return null;
    });
    await _ensureHiveBoxes();
  });
  tearDownAll(() async {
    await _cleanupHive();
    final binding = TestDefaultBinaryMessengerBinding.instance;
    final pathProvChannel = const MethodChannel('plugins.flutter.io/path_provider');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvChannel, null);
  });
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
