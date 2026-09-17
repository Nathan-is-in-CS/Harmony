// This is your app. It runs as it is: press run and you get the screen below.
//
// Nothing here is precious. Change the title, change the colors, delete the
// counter, add your own screens. It exists so that the repository is a working
// Flutter app from minute one instead of an empty folder.
//
// Everything in this file is Module 4 and 5 material: StatelessWidget,
// StatefulWidget, setState, Scaffold, AppBar, Column, Card, FilledButton.

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/library_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tracks_box');

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Final Project',
      debugShowCheckedModeBanner: false,

      // These two lines are what make the DevicePreview toolbar actually
      // change the app. Keep them.
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      // Your design system starts here. One seed color generates a full
      // Material palette; swap in your own and every screen follows.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
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
