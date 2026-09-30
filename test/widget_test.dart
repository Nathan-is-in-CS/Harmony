// A widget test: it builds your app in memory and checks what is on screen.
// Run them all with: flutter test
//
// You are not required to write more of these, but a project with a few real
// tests reads very differently from one with none.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:harmony/main.dart';
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
    // Prevent LibraryScreen from scanning device audio during widget tests.
    final settings = Hive.box('settings_box');
    await settings.put('device_audio_scanned', true);
    // Ensure tracks_box is non-empty so the initial scan early-exits.
    final tracks = Hive.box('tracks_box');
    if (tracks.isEmpty) {
      await tracks.add({
        'id': '__test_track',
        'title': 'Autumn Leaves',
        'path': '/tmp/autumn_leaves.mp3',
        'bpm': 120,
        'keySignature': 'C',
        'isUserVerified': false,
      });
    }
  });

  tearDownAll(() async {
    final binding = TestDefaultBinaryMessengerBinding.instance;
    final pathProvChannel = const MethodChannel('plugins.flutter.io/path_provider');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvChannel, null);
  });

  testWidgets('home screen builds and disposes cleanly', (tester) async {
    addTearDown(() async {
      // Dispose the widget tree before the test isolate exits. LibraryScreen
      // listens to the Hive box and must release that listener first.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    await tester.pumpWidget(const MyApp());
  });
}
