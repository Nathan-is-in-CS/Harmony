import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/library_screen.dart';
import 'theme/harmony_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tracks_box');
  await Hive.openBox('audio_blobs');
  await Hive.openBox('lyrics_box');
  await Hive.openBox('settings_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harmony',
      debugShowCheckedModeBanner: false,

      theme: buildHarmonyTheme(),
      themeMode: ThemeMode.light,

      home: const LibraryScreen(),
    );
  }
}
