// This is your app. It runs as it is: press run and you get the screen below.
//
// Nothing here is precious. Change the title, change the colors, delete the
// counter, add your own screens. It exists so that the repository is a working
// Flutter app from minute one instead of an empty folder.
//
// Everything in this file is Module 4 and 5 material: StatelessWidget,
// StatefulWidget, setState, Scaffold, AppBar, Column, Card, FilledButton.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/library_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tracks_box');
  await Hive.openBox('audio_blobs');
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

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F2A44),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F2EF),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFE7E5E2),
          foregroundColor: Colors.black,
        ),
      ),

      home: const LibraryScreen(),
    );
  }
}

/// The first screen. Replace it with yours.
///
/// It is a StatefulWidget because it remembers something that changes: the
/// counter. A screen that never changes can be a StatelessWidget instead.
// Note: HomeScreen replaced by LibraryScreen in a separate file.
