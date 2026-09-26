import 'dart:io';
import 'package:path_provider/path_provider.dart';

String normalizeAudioPath(String path) => path.trim().replaceAll('\\', '/');

Future<String> canonicalizeAudioPath(String path) async {
  final normalized = normalizeAudioPath(path);
  if (normalized.isEmpty) return normalized;

  try {
    final file = File(normalized);
    if (await file.exists()) {
      return normalizeAudioPath((await file.resolveSymbolicLinks()).replaceAll('\\', '/'));
    }
  } catch (_) {
    // fall back to normalized path if canonical resolution is unavailable
  }

  return normalized;
}

Future<List<String>> deduplicateAudioPaths(Iterable<String> paths) async {
  final seen = <String>{};
  final result = <String>[];

  for (final path in paths) {
    final canonical = await canonicalizeAudioPath(path);
    if (canonical.isEmpty) continue;
    if (seen.add(canonical)) {
      result.add(canonical);
    }
  }

  return result;
}

bool isAudioFilePath(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mp3') ||
      lower.endsWith('.wav') ||
      lower.endsWith('.m4a') ||
      lower.endsWith('.aac') ||
      lower.endsWith('.flac') ||
      lower.endsWith('.ogg') ||
      lower.endsWith('.wma') ||
      lower.endsWith('.aiff');
}

bool shouldSkipDirectory(String path) {
  final lower = path.toLowerCase();
  return lower.contains('/android') ||
      lower.contains('/cache') ||
      lower.contains('/tmp') ||
      lower.contains('/proc') ||
      lower.contains('/system') ||
      lower.contains('/data/data');
}

Future<List<String>> findAudioFilesOnDevice() async {
  final candidates = <String>[];
  final seen = <String>{};

  Future<void> crawl(Directory dir) async {
    try {
      final exists = await dir.exists();
      if (!exists) return;
    } catch (_) {
      return;
    }

    try {
      final entities = await dir.list().toList();
      for (final entity in entities) {
        if (entity is File) {
          if (isAudioFilePath(entity.path) && !seen.contains(entity.path)) {
            seen.add(entity.path);
            candidates.add(entity.path);
          }
        } else if (entity is Directory) {
          final path = entity.path.toLowerCase();
          if (shouldSkipDirectory(path)) continue;
          await crawl(entity);
        }
      }
    } catch (_) {
      // ignore unreadable folders
    }
  }

  final roots = <Directory>[];
  if (Platform.isWindows) {
    final home = Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      roots.add(Directory('$home\\Music'));
      roots.add(Directory('$home\\OneDrive\\Music'));
    }
  } else if (Platform.isMacOS) {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      roots.add(Directory('$home/Music'));
      roots.add(Directory('$home/Downloads'));
    }
  } else {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      roots.add(Directory('$home/Music'));
      roots.add(Directory('$home/Downloads'));
    }

    final androidRoots = <Directory>[
      Directory('/sdcard/Music'),
      Directory('/sdcard/Download'),
      Directory('/sdcard/Downloads'),
      Directory('/storage/emulated/0/Music'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/Downloads'),
      Directory('/storage/self/primary/Music'),
      Directory('/storage/self/primary/Download'),
      Directory('/storage/self/primary/Downloads'),
    ];

    for (final candidate in androidRoots) {
      if (!roots.any((root) => root.path == candidate.path)) {
        roots.add(candidate);
      }
    }

    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && !roots.any((root) => root.path == downloadsDir.path)) {
        roots.add(downloadsDir);
      }
    } catch (_) {
      // ignore unsupported storage locations
    }

    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null && !roots.any((dir) => dir.path == externalDir.path)) {
        roots.add(externalDir);
      }
    } catch (_) {
      // ignore storage access failures on unsupported/emulator setups
    }
  }

  final appDir = await getApplicationDocumentsDirectory();
  roots.add(Directory(appDir.path));

  for (final root in roots) {
    await crawl(root);
  }

  candidates.sort();
  return candidates;
}

Future<String> copyFileToAppDir(String sourcePath, String fileName) async {
  final appDoc = await getApplicationDocumentsDirectory();
  final audioDir = Directory('${appDoc.path}${Platform.pathSeparator}audio');
  if (!await audioDir.exists()) await audioDir.create(recursive: true);
  final dest = File('${audioDir.path}${Platform.pathSeparator}$fileName');
  final copied = await File(sourcePath).copy(dest.path);
  return copied.path;
}

Future<void> deleteIfInAppDir(String filePath) async {
  final appDoc = await getApplicationDocumentsDirectory();
  final audioDirPath = '${appDoc.path}${Platform.pathSeparator}audio${Platform.pathSeparator}';
  if (filePath.startsWith(audioDirPath)) {
    final f = File(filePath);
    if (await f.exists()) await f.delete();
  }
}
