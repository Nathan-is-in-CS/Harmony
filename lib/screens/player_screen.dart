import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/track_model.dart';

class PlayerScreen extends StatefulWidget {
  final TrackModel track;
  const PlayerScreen({super.key, required this.track});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late TrackModel _track;
  bool _isPlaying = false;
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;
  String? _errorMessage;
  PlayerState? _playerState;
  final List<int> _tapTimes = [];
  double? _tapBpm;

  @override
  void initState() {
    super.initState();
    _track = widget.track;
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
        _playerState = state;
        if (state == PlayerState.playing || state == PlayerState.paused || state == PlayerState.stopped || state == PlayerState.completed) {
          _isBuffering = false;
        }
      });
    });
    _player.onPositionChanged.listen((p) {
      setState(() {
        _position = p;
      });
    });
    _player.onDurationChanged.listen((d) {
      setState(() {
        _duration = d;
      });
    });
    _player.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  Future<void> _togglePlay() async {
    if (_playerState == PlayerState.paused) {
      try {
        await _player.resume();
        return;
      } catch (e) {
        _errorMessage = e.toString();
        if (mounted) setState(() {});
        return;
      }
    }

    if (!_isPlaying) {
      if (_track.path.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No audio file attached for this track.')));
        return;
      }
      try {
        setState(() {
          _isBuffering = true;
          _errorMessage = null;
        });
        if (_track.path.startsWith('http')) {
          await _player.play(UrlSource(_track.path));
        } else if (_track.path.startsWith('bytes:')) {
          final key = _track.path.substring('bytes:'.length);
          final box = Hive.box('audio_blobs');
          final raw = box.get(key);
          if (raw is Uint8List) {
            await _player.play(BytesSource(raw));
          } else {
            throw 'No audio bytes found';
          }
        } else {
          await _player.play(DeviceFileSource(_track.path));
        }
        setState(() {
          _isPlaying = true;
          _isBuffering = false;
        });
      } catch (e) {
        _errorMessage = e.toString();
        setState(() {
          _isBuffering = false;
        });
      }
    } else {
      await _player.pause();
      setState(() => _isPlaying = false);
    }
  }

  void _handleTapTempo() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _tapTimes.add(now);

    if (_tapTimes.length > 8) {
      _tapTimes.removeAt(0);
    }

    if (_tapTimes.length >= 2) {
      final diffs = <int>[];
      for (var i = 1; i < _tapTimes.length; i++) {
        diffs.add(_tapTimes[i] - _tapTimes[i - 1]);
      }
      final average = diffs.reduce((a, b) => a + b) / diffs.length;
      if (average > 0) {
        final bpm = 60000 / average;
        setState(() {
          _tapBpm = bpm;
        });
      }
    }
  }

  Future<void> _retryPlay() async {
    _errorMessage = null;
    setState(() {});
    await _togglePlay();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _showCalibrationSheet() async {
    final bpmController = TextEditingController(text: _track.bpm.toStringAsFixed(0));
    final keyController = TextEditingController(text: _track.keySignature);
    bool verified = _track.isUserVerified;

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Calibration', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bpmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'BPM'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter BPM';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'Enter a valid BPM';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: keyController,
                    decoration: const InputDecoration(labelText: 'Key Signature'),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: verified,
                    onChanged: (v) => verified = v ?? false,
                    title: const Text('Mark as verified'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState?.validate() ?? false) {
                            final newBpm = double.parse(bpmController.text);
                            final newKey = keyController.text;
                            // update hive box record matching this track id
                            final box = Hive.box('tracks_box');
                            for (var i = 0; i < box.length; i++) {
                              final raw = box.getAt(i) as Map<dynamic, dynamic>;
                              if ((raw['id'] as String?) == _track.id) {
                                final updated = TrackModel(
                                  id: _track.id,
                                  title: _track.title,
                                  path: _track.path,
                                  bpm: newBpm,
                                  keySignature: newKey,
                                  isUserVerified: verified,
                                );
                                await box.putAt(i, updated.toMap());
                                if (mounted) {
                                  _track = updated;
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calibration saved')));
                                }
                                break;
                              }
                            }
                            Navigator.of(ctx).pop();
                            if (mounted) setState(() {});
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _track;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, size: 42, color: Colors.black54),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text('Key: ${t.keySignature} • ${t.bpm.toStringAsFixed(0)} BPM', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87)),
                          const SizedBox(height: 6),
                          if (_tapBpm != null)
                            Text('Tap BPM: ${_tapBpm!.toStringAsFixed(1)}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: AnimatedScale(
                scale: _isPlaying ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _togglePlay,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isBuffering) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      if (!_isBuffering) Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 28),
                      const SizedBox(width: 8),
                      Text(_errorMessage != null ? 'Error' : (_isPlaying ? 'Pause' : 'Play'), style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      if (_errorMessage != null)
                        IconButton(icon: const Icon(Icons.refresh), tooltip: 'Retry', onPressed: _retryPlay),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _tapBpm == null ? 'Tap to measure BPM' : 'Tap BPM: ${_tapBpm!.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _handleTapTempo,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tap'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    thumbColor: Theme.of(context).colorScheme.primary,
                    overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1).toDouble(),
                    onChanged: (_duration.inMilliseconds > 0)
                        ? (value) {
                            setState(() {
                              _position = Duration(milliseconds: value.toInt());
                            });
                          }
                        : null,
                    onChangeEnd: (_duration.inMilliseconds > 0)
                        ? (value) async {
                            await _player.seek(Duration(milliseconds: value.toInt()));
                          }
                        : null,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_format(_position), style: Theme.of(context).textTheme.bodySmall),
                    Text(_format(_duration), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('BPM', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 6),
                      Text(t.bpm.toStringAsFixed(0), style: Theme.of(context).textTheme.titleLarge),
                    ]),
                    ElevatedButton.icon(onPressed: _showCalibrationSheet, icon: const Icon(Icons.tune), label: const Text('Edit'))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
