import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/track_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../src/platform_io_nonweb.dart' if (dart.library.html) '../src/platform_io_web.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

Widget _buildMiniPlayer(BuildContext context, HarmonyAudioController controller) {
  final currentTrack = controller.currentTrack.value;
  if (currentTrack == null) {
    return const SizedBox.shrink();
  }

  return ValueListenableBuilder<bool>(
    valueListenable: controller.isPlaying,
    builder: (context, isPlaying, _) {
      return ValueListenableBuilder<Duration>(
        valueListenable: controller.position,
        builder: (context, position, _) {
          return ValueListenableBuilder<Duration>(
            valueListenable: controller.duration,
            builder: (context, duration, _) {
              return Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PlayerScreen(track: currentTrack)),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEE7FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Color(0xFF2C2A6B)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTrack.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              () {
                                final parts = <String>[
                                  if (currentTrack.keySignature.isNotEmpty) currentTrack.keySignature,
                                  if (currentTrack.bpm > 0) '${currentTrack.bpm.toStringAsFixed(0)} BPM',
                                ];
                                return parts.isEmpty ? 'Metadata not set' : parts.join(' • ');
                              }(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (isPlaying) {
                            await controller.pause();
                          } else {
                            await controller.resume();
                          }
                        },
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow_rounded),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum _TrackSort { title, bpm, verified }

class _LibraryScreenState extends State<LibraryScreen> {
  late Box _tracksBox;
  late final Box _settingsBox;
  bool _isScanning = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _TrackSort _trackSort = _TrackSort.title;

  @override
  void initState() {
    super.initState();
    _tracksBox = Hive.box('tracks_box');
    _settingsBox = Hive.box('settings_box');
    _migrateTrackIdsIfNeeded();
    _runInitialDeviceScan();
  }

  Future<void> _migrateTrackIdsIfNeeded() async {
    try {
      final lyricsBox = Hive.box('lyrics_box');
      for (var i = 0; i < _tracksBox.length; i++) {
        final raw = _tracksBox.getAt(i);
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final track = TrackModel.fromMap(map);
        if (track.path.isNotEmpty && track.id != track.path) {
          final oldId = track.id;
          final newId = track.path;
          final updated = TrackModel(
            id: newId,
            title: track.title,
            path: track.path,
            bpm: track.bpm,
            keySignature: track.keySignature,
            isUserVerified: track.isUserVerified,
          );
          await _tracksBox.putAt(i, updated.toMap());
          // migrate lyrics if present
          if (lyricsBox.containsKey(oldId) && !lyricsBox.containsKey(newId)) {
            final val = lyricsBox.get(oldId);
            await lyricsBox.put(newId, val);
            await lyricsBox.delete(oldId);
          }
        }
      }
    } catch (e) {
      // migration best-effort; don't block app
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<dynamic, dynamic>> _filteredTrackMaps(Box box) {
    final query = _searchQuery.trim().toLowerCase();
    final matches = <Map<dynamic, dynamic>>[];

    for (var index = 0; index < box.length; index++) {
      final raw = box.getAt(index);
      if (raw is! Map) continue;
      final map = Map<dynamic, dynamic>.from(raw);
      final track = TrackModel.fromMap(map);
      if (query.isEmpty) {
        matches.add(map);
        continue;
      }

      final haystack = '${track.title} ${track.path} ${track.keySignature}'.toLowerCase();
      if (haystack.contains(query)) {
        matches.add(map);
      }
    }

    switch (_trackSort) {
      case _TrackSort.title:
        matches.sort((a, b) {
          final ta = TrackModel.fromMap(a);
          final tb = TrackModel.fromMap(b);
          return ta.title.toLowerCase().compareTo(tb.title.toLowerCase());
        });
        break;
      case _TrackSort.bpm:
        matches.sort((a, b) {
          final ta = TrackModel.fromMap(a);
          final tb = TrackModel.fromMap(b);
          return tb.bpm.compareTo(ta.bpm);
        });
        break;
      case _TrackSort.verified:
        matches.sort((a, b) {
          final ta = TrackModel.fromMap(a);
          final tb = TrackModel.fromMap(b);
          if (ta.isUserVerified == tb.isUserVerified) {
            return ta.title.toLowerCase().compareTo(tb.title.toLowerCase());
          }
          return tb.isUserVerified ? 1 : -1;
        });
        break;
    }

    return matches;
  }

  Future<bool> _requestAudioPermission() async {
    if (!Platform.isAndroid) return true;

    final audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted) return true;

    final audioRequest = await Permission.audio.request();
    if (audioRequest.isGranted) return true;

    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;

    final storageRequest = await Permission.storage.request();
    return storageRequest.isGranted;
  }

  Future<void> _runInitialDeviceScan() async {
    final alreadyScanned = _settingsBox.get('device_audio_scanned', defaultValue: false) as bool;
    if (alreadyScanned && _tracksBox.isNotEmpty) return;

    final hasPermission = await _requestAudioPermission();
    if (!hasPermission) {
      await _settingsBox.put('device_audio_scanned', false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage access is required to scan your local audio files.')),
        );
      }
      return;
    }

    await _scanDeviceAudioFiles();
  }

  Future<void> _toggleVerified(TrackModel track) async {
    for (var index = 0; index < _tracksBox.length; index++) {
      final raw = _tracksBox.getAt(index);
      if (raw is! Map) continue;
      final existing = TrackModel.fromMap(Map<String, dynamic>.from(raw));
      if (existing.id != track.id) continue;

      final updated = TrackModel(
        id: existing.id,
        title: existing.title,
        path: existing.path,
        bpm: existing.bpm,
        keySignature: existing.keySignature,
        isUserVerified: !existing.isUserVerified,
      );

      await _tracksBox.putAt(index, updated.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.isUserVerified ? 'Marked ${track.title} as verified' : 'Removed verification from ${track.title}',
            ),
          ),
        );
      }
      break;
    }

    if (mounted) setState(() {});
  }

  Future<void> _removeTrack(TrackModel track) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove track?'),
        content: Text('Delete "${track.title}" from your local Harmony library?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    for (var index = 0; index < _tracksBox.length; index++) {
      final raw = _tracksBox.getAt(index);
      if (raw is! Map) continue;
      final existing = TrackModel.fromMap(Map<String, dynamic>.from(raw));
      if (existing.id == track.id) {
        await _tracksBox.deleteAt(index);
        // remove any associated lyrics
        try {
          final lyricsBox = Hive.box('lyrics_box');
          if (lyricsBox.containsKey(track.id)) {
            await lyricsBox.delete(track.id);
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed ${track.title} from the library')),
          );
        }
        break;
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _scanDeviceAudioFiles({bool includeExisting = false}) async {
    if (_isScanning) return;

    final hasPermission = await _requestAudioPermission();
    if (!hasPermission) {
      await _settingsBox.put('device_audio_scanned', false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage access is required to scan your local audio files.')),
        );
      }
      return;
    }

    setState(() => _isScanning = true);
    try {
      if (kIsWeb) {
        await _settingsBox.put('device_audio_scanned', true);
        return;
      }

      final discovered = await findAudioFilesOnDevice();
      if (discovered.isEmpty) {
        await _settingsBox.put('device_audio_scanned', false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No local audio files were found on this device.')),
          );
        }
        return;
      }

      final existingPaths = <String>{};
      for (var i = 0; i < _tracksBox.length; i++) {
        final raw = _tracksBox.getAt(i) as Map<dynamic, dynamic>?;
        if (raw == null) continue;
        final track = TrackModel.fromMap(raw);
        if (track.path.isNotEmpty) {
          existingPaths.add(normalizeAudioPath(track.path));
        }
      }

      final discoveredUnique = await deduplicateAudioPaths(discovered);
      var added = 0;
      for (final rawPath in discoveredUnique) {
        final normalizedPath = normalizeAudioPath(rawPath);
        final canonicalPath = await canonicalizeAudioPath(normalizedPath);
        if (existingPaths.contains(canonicalPath)) continue;
        if (_tracksBox.values.any((entry) {
          if (entry is! Map) return false;
          final track = TrackModel.fromMap(Map<String, dynamic>.from(entry));
          return normalizeAudioPath(track.path) == canonicalPath || normalizeAudioPath(track.path) == normalizedPath;
        })) {
          continue;
        }

        final fileName = canonicalPath.replaceAll(RegExp(r'^.*[/\\]'), '');
        final title = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
        final stableId = canonicalPath; // use canonical path as stable id
        final track = TrackModel(
          id: stableId,
          title: title.isEmpty ? 'Untitled track' : title,
          path: canonicalPath,
          // Discovery only knows the file path. BPM and key must be entered
          // by the user before this track has usable musical metadata.
          bpm: 0,
          keySignature: '',
          isUserVerified: false,
        );

        _tracksBox.add(track.toMap());
        existingPaths.add(canonicalPath);
        added++;
      }

      await _settingsBox.put('device_audio_scanned', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(added > 0 ? 'Analyzed $added new audio file(s)' : 'Device audio already up to date')),
        );
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = HarmonyAudioController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Library'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          PopupMenuButton<_TrackSort>(
            tooltip: 'Sort tracks',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (sort) => setState(() => _trackSort = sort),
            itemBuilder: (context) => [
              const PopupMenuItem(value: _TrackSort.title, child: Text('Sort: Title')),
              const PopupMenuItem(value: _TrackSort.bpm, child: Text('Sort: BPM')),
              const PopupMenuItem(value: _TrackSort.verified, child: Text('Sort: Verified')),
            ],
          ),
          IconButton(
            onPressed: _isScanning ? null : () => _scanDeviceAudioFiles(includeExisting: true),
            icon: _isScanning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search_rounded),
            tooltip: 'Analyze device audio',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search your tracks',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _tracksBox.listenable(),
              builder: (context, Box box, _) {
                final filteredTracks = _filteredTrackMaps(box);
                if (box.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.library_music_rounded, size: 52, color: Colors.black45),
                          const SizedBox(height: 12),
                          Text(
                            _isScanning ? 'Scanning your device for local audio…' : 'No local tracks yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isScanning
                                ? 'Harmony is analyzing your device storage for downloaded audio files.'
                                : 'Tap below to scan your device for stored music and start your local library.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _isScanning ? null : () => _scanDeviceAudioFiles(includeExisting: true),
                            icon: const Icon(Icons.search_rounded),
                            label: Text(_isScanning ? 'Scanning…' : 'Analyze device audio'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (filteredTracks.isEmpty) {
                  return const Center(child: Text('No tracks match your search'));
                }
                return ListView.builder(
                  itemCount: filteredTracks.length,
                  itemBuilder: (context, index) {
                    final raw = filteredTracks[index];
                    final track = TrackModel.fromMap(raw);
                    final queue = filteredTracks.map((entry) => TrackModel.fromMap(Map<String, dynamic>.from(entry))).toList();
                    return ListTile(
                      leading: const Icon(Icons.audiotrack),
                      title: Text(track.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.bpm > 0
                                ? '${track.bpm.toStringAsFixed(0)} BPM • ${track.keySignature}'
                                : 'BPM and key not set',
                          ),
                          if (track.path.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              track.path,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (track.isUserVerified)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: const Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 12)),
                                backgroundColor: Colors.black87,
                              ),
                            ),
                          IconButton(
                            tooltip: track.isUserVerified ? 'Unverify track' : 'Verify track',
                            icon: Icon(
                              track.isUserVerified ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                              color: track.isUserVerified ? Theme.of(context).colorScheme.primary : Colors.grey,
                            ),
                            onPressed: () => _toggleVerified(track),
                          ),
                          IconButton(
                            tooltip: 'Delete track',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _removeTrack(track),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final sourceQueue = queue.isNotEmpty ? queue : [track];
                        await controller.playTrack(track, sourceQueue: sourceQueue);

                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PlayerScreen(track: track)),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          ValueListenableBuilder<TrackModel?>(
            valueListenable: controller.currentTrack,
            builder: (context, currentTrack, _) {
              if (currentTrack == null) {
                return const SizedBox.shrink();
              }
              return _buildMiniPlayer(context, controller);
            },
          ),
        ],
      ),
    );
  }
}
