import 'package:flutter_test/flutter_test.dart';
import 'package:harmony/screens/player_screen.dart';
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
    // Mock path_provider platform channel so tests don't call real plugins.
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
    // Clear path_provider mock.
    final binding = TestDefaultBinaryMessengerBinding.instance;
    final pathProvChannel = const MethodChannel('plugins.flutter.io/path_provider');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvChannel, null);
  });
  group('PlayerScreen progression guards', () {
    test('returns zero progress when duration is unknown or zero', () async {
      expect(PlayerScreen.sliderValueFor(Duration.zero, Duration.zero), 0.0);
      expect(PlayerScreen.sliderValueFor(const Duration(seconds: 3), Duration.zero), 0.0);
    });

    test('clamps progress to the valid millisecond range', () async {
      expect(PlayerScreen.sliderValueFor(const Duration(seconds: 8), const Duration(seconds: 4)), 4000.0);
      expect(PlayerScreen.sliderValueFor(const Duration(seconds: -1), const Duration(seconds: 4)), 0.0);
    });

    test('computes the raw position in milliseconds for a valid duration', () async {
      expect(PlayerScreen.sliderValueFor(const Duration(seconds: 2), const Duration(seconds: 4)), closeTo(2000.0, 0.0001));
    });
  });
}
