import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/track_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../src/platform_io_nonweb.dart' if (dart.library.html) '../src/platform_io_web.dart';
import 'player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Box _tracksBox;

  @override
  void initState() {
    super.initState();
    _tracksBox = Hive.box('tracks_box');
    // If empty, populate with sample data so the app shows something.
    if (_tracksBox.isEmpty) {
      final sample = [
        TrackModel(
          id: '1',
          title: 'Autumn Leaves',
          path: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          bpm: 132,
          keySignature: 'G Minor',
          isUserVerified: true,
        ),
        TrackModel(
          id: '2',
          title: 'Blue Bossa',
          path: '',
          bpm: 150,
          keySignature: 'C Minor',
          isUserVerified: false,
        ),
      ];
      for (var t in sample) {
        _tracksBox.add(t.toMap());
      }
    }
  }

  void _addDummyTrack() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final t = TrackModel(
      id: id,
      title: 'New Track $id',
      path: '',
      bpm: 120,
      keySignature: 'C Major',
      isUserVerified: false,
    );
    _tracksBox.add(t.toMap());
    setState(() {});
  }

  Future<void> _attachLocalFile(int index) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: kIsWeb);
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    if (kIsWeb) {
      // save bytes into Hive and reference by key
      final bytes = picked.bytes;
      if (bytes == null) return;
      final audioBox = Hive.box('audio_blobs');
      final key = DateTime.now().millisecondsSinceEpoch.toString();
      await audioBox.put(key, bytes);
      final raw = _tracksBox.getAt(index) as Map<dynamic, dynamic>;
      final track = TrackModel.fromMap(raw);
      final updated = TrackModel(
        id: track.id,
        title: track.title,
        path: 'bytes:$key',
        bpm: track.bpm,
        keySignature: track.keySignature,
        isUserVerified: track.isUserVerified,
      );
      await _tracksBox.putAt(index, updated.toMap());
    } else {
      final path = picked.path;
      if (path == null) return;
      // copy to app documents/audio for mobile persistence (uses platform helper)
      try {
        final fileName = picked.name;
        final newPath = await copyFileToAppDir(path, fileName);
        final raw = _tracksBox.getAt(index) as Map<dynamic, dynamic>;
        final track = TrackModel.fromMap(raw);
        final updated = TrackModel(
          id: track.id,
          title: track.title,
          path: newPath,
          bpm: track.bpm,
          keySignature: track.keySignature,
          isUserVerified: track.isUserVerified,
        );
        await _tracksBox.putAt(index, updated.toMap());
      } catch (e) {
        // fallback to storing original path
        final raw = _tracksBox.getAt(index) as Map<dynamic, dynamic>;
        final track = TrackModel.fromMap(raw);
        final updated = TrackModel(
          id: track.id,
          title: track.title,
          path: path,
          bpm: track.bpm,
          keySignature: track.keySignature,
          isUserVerified: track.isUserVerified,
        );
        await _tracksBox.putAt(index, updated.toMap());
      }
    }
    setState(() {});
  }

  Future<void> _confirmRemove(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove attachment'),
        content: const Text('Are you sure you want to remove the attached audio from this track? This will not delete the original file if it exists outside the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await _removeAttachment(index);
    }
  }

  Future<void> _removeAttachment(int index) async {
    final raw = _tracksBox.getAt(index) as Map<dynamic, dynamic>;
    final track = TrackModel.fromMap(raw);
    final path = track.path;
      try {
        if (path.startsWith('bytes:')) {
          final key = path.substring('bytes:'.length);
          final audioBox = Hive.box('audio_blobs');
          if (audioBox.containsKey(key)) await audioBox.delete(key);
        } else if (path.isNotEmpty) {
          // attempt to delete file only if it resides in app dir (helper handles web)
          await deleteIfInAppDir(path);
        }

      final updated = TrackModel(
        id: track.id,
        title: track.title,
        path: '',
        bpm: track.bpm,
        keySignature: track.keySignature,
        isUserVerified: track.isUserVerified,
      );
      await _tracksBox.putAt(index, updated.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment removed')));
      }
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove attachment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Library'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _addDummyTrack,
            icon: const Icon(Icons.add),
            tooltip: 'Add sample track',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _tracksBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No tracks yet'));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final raw = box.getAt(index) as Map<dynamic, dynamic>;
              final track = TrackModel.fromMap(raw);
              return ListTile(
                leading: const Icon(Icons.audiotrack),
                title: Text(track.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${track.bpm.toStringAsFixed(0)} BPM • ${track.keySignature}'),
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
                      tooltip: 'Attach audio file',
                      icon: const Icon(Icons.attach_file),
                      onPressed: () => _attachLocalFile(index),
                    ),
                    if (track.path.isNotEmpty)
                      IconButton(
                        tooltip: 'Remove attachment',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmRemove(index),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PlayerScreen(track: track)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
