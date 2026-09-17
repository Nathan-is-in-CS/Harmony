import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/track_model.dart';

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
          path: '',
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
                subtitle: Text('${track.bpm.toStringAsFixed(0)} BPM • ${track.keySignature}'),
                trailing: track.isUserVerified
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('[ VERIFIED ]', style: TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
