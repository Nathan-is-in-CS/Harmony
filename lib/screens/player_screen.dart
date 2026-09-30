import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'lyrics_import_sheet.dart';
import '../src/lyrics/lyrics_view.dart';
import '../models/track_model.dart';

enum PlaybackMode { normal, shuffle, repeatAll, repeatOne }

const _musicKeySignatures = [
  'C major', 'G major', 'D major', 'A major', 'E major', 'B major', 'F# major', 'C# major',
  'F major', 'Bb major', 'Eb major', 'Ab major', 'Db major', 'Gb major', 'Cb major',
  'A minor', 'E minor', 'B minor', 'F# minor', 'C# minor', 'G# minor', 'D# minor', 'A# minor',
  'D minor', 'G minor', 'C minor', 'F minor', 'Bb minor', 'Eb minor', 'Ab minor',
];

class HarmonyAudioController {
  HarmonyAudioController._();

  static final HarmonyAudioController instance = HarmonyAudioController._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<TrackModel?> currentTrack = ValueNotifier(null);
  final ValueNotifier<List<TrackModel>> queue = ValueNotifier(const []);
  final ValueNotifier<int> currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<PlaybackMode> playbackMode = ValueNotifier(PlaybackMode.normal);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  bool _isInitialized = false;
  Timer? _pollTimer;
  DateTime? _manualStateGuardUntil;
  bool? _manualPlayingState;
  final List<TrackModel> _baseQueue = [];
  final List<StreamSubscription> _subscriptions = [];

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _player.setPlayerMode(PlayerMode.mediaPlayer);
    await _player.setReleaseMode(ReleaseMode.release);
    await _player.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ),
    );

    _subscriptions.add(_player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;

      // audioplayers can deliver a stale state event after pause/resume,
      // especially for BytesSource and DeviceFileSource. Do not let that
      // event overwrite the state requested by the most recent user action.
      final guardActive = _manualStateGuardUntil?.isAfter(DateTime.now()) ?? false;
      if (guardActive && _manualPlayingState != playing) {
        return;
      }
      _manualStateGuardUntil = null;
      _manualPlayingState = null;

      isPlaying.value = playing;
      if (playing) {
        _startPolling();
      } else {
        _stopPolling();
      }
      if (state == PlayerState.completed) {
        position.value = Duration.zero;
      }
    }));
    _subscriptions.add(_player.onPositionChanged.listen((p) => position.value = p));
    _subscriptions.add(_player.onDurationChanged.listen((d) => duration.value = d));
    _subscriptions.add(_player.onPlayerComplete.listen((_) {
      position.value = Duration.zero;
      _advanceAfterCompletion();
    }));
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 250), (_) async {
      if (!isPlaying.value) return;
      final current = await _player.getCurrentPosition();
      if (current != null) {
        position.value = current;
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _setPlayingState(bool playing, {bool guardStaleEvent = false}) {
    if (guardStaleEvent) {
      _manualPlayingState = playing;
      _manualStateGuardUntil = DateTime.now().add(const Duration(milliseconds: 750));
    } else {
      _manualPlayingState = null;
      _manualStateGuardUntil = null;
    }
    isPlaying.value = playing;
    if (playing) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void setQueue(List<TrackModel> tracks, {int startIndex = 0}) {
    if (tracks.isEmpty) {
      _baseQueue.clear();
      queue.value = const [];
      currentTrack.value = null;
      currentIndex.value = 0;
      return;
    }

    _baseQueue
      ..clear()
      ..addAll(tracks);

    final safeIndex = startIndex.clamp(0, tracks.length - 1);
    queue.value = List<TrackModel>.from(tracks);
    currentIndex.value = safeIndex;
    currentTrack.value = queue.value[safeIndex];
  }

  Future<void> playTrack(TrackModel track, {List<TrackModel>? sourceQueue}) async {
    await initialize();
    errorMessage.value = null;

    if (sourceQueue != null && sourceQueue.isNotEmpty) {
      setQueue(sourceQueue, startIndex: sourceQueue.indexWhere((t) => t.id == track.id));
    } else if (currentTrack.value == null || currentTrack.value!.id != track.id) {
      currentTrack.value = track;
      queue.value = [track];
      currentIndex.value = 0;
    }

    currentTrack.value = track;
    position.value = Duration.zero;
    duration.value = Duration.zero;

    if (track.path.isEmpty) {
      errorMessage.value = 'No audio file attached for this track.';
      _setPlayingState(false);
      return;
    }

    try {
      if (track.path.startsWith('http')) {
        await _player.play(UrlSource(track.path));
      } else if (track.path.startsWith('bytes:')) {
        final key = track.path.substring('bytes:'.length);
        final box = Hive.box('audio_blobs');
        final raw = box.get(key);
        if (raw is Uint8List) {
          await _player.play(BytesSource(raw));
        } else {
          throw 'No audio bytes found';
        }
      } else {
        await _player.play(DeviceFileSource(track.path));
      }

      Duration? maybeDuration;
      for (var attempt = 0; attempt < 4; attempt++) {
        maybeDuration = await _player.getDuration();
        if (maybeDuration != null && maybeDuration.inMilliseconds > 0) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      if (maybeDuration != null && maybeDuration.inMilliseconds > 0) {
        duration.value = maybeDuration;
      }

      _setPlayingState(true);
    } catch (e) {
      errorMessage.value = e.toString();
      _setPlayingState(false);
    }
  }

  Future<void> togglePlay() async {
    if (isPlaying.value) {
      await _player.pause();
      _setPlayingState(false, guardStaleEvent: true);
      return;
    }

    final track = currentTrack.value;
    if (track == null) {
      return;
    }

    if (_player.state == PlayerState.paused) {
      await _player.resume();
      _setPlayingState(true, guardStaleEvent: true);
      return;
    }

    await playTrack(track, sourceQueue: queue.value);
  }

  Future<void> pause() async {
    await _player.pause();
    _setPlayingState(false, guardStaleEvent: true);
  }

  Future<void> resume() async {
    await _player.resume();
    _setPlayingState(true, guardStaleEvent: true);
  }

  Future<void> seek(Duration value) async {
    await _player.seek(value);
    final now = await _player.getCurrentPosition();
    if (now != null) {
      position.value = now;
    }
  }

  Future<void> nextTrack() async {
    if (queue.value.isEmpty) return;

    switch (playbackMode.value) {
      case PlaybackMode.repeatOne:
        await _player.seek(Duration.zero);
        await _player.resume();
        _setPlayingState(true);
        return;
      case PlaybackMode.shuffle:
        final currentId = currentTrack.value?.id;
        final available = queue.value.where((t) => t.id != currentId).toList();
        if (available.isEmpty) {
          await _player.seek(Duration.zero);
          await _player.resume();
          _setPlayingState(true);
          return;
        }
        final next = available[(available.length * DateTime.now().microsecondsSinceEpoch % available.length).abs()];
        final nextIndex = queue.value.indexWhere((t) => t.id == next.id);
        if (nextIndex >= 0) {
          currentIndex.value = nextIndex;
          currentTrack.value = next;
          await playTrack(next, sourceQueue: queue.value);
        }
        return;
      case PlaybackMode.repeatAll:
      case PlaybackMode.normal:
        final nextIndex = currentIndex.value + 1;
        if (nextIndex < queue.value.length) {
          final next = queue.value[nextIndex];
          currentIndex.value = nextIndex;
          currentTrack.value = next;
          await playTrack(next, sourceQueue: queue.value);
        } else if (playbackMode.value == PlaybackMode.repeatAll) {
          final next = queue.value.first;
          currentIndex.value = 0;
          currentTrack.value = next;
          await playTrack(next, sourceQueue: queue.value);
        } else {
          await _player.stop();
          _setPlayingState(false);
        }
    }
  }

  Future<void> previousTrack() async {
    if (position.value > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      position.value = Duration.zero;
      return;
    }

    if (queue.value.isEmpty) return;

    if (currentIndex.value > 0) {
      final previous = queue.value[currentIndex.value - 1];
      currentIndex.value = currentIndex.value - 1;
      currentTrack.value = previous;
      await playTrack(previous, sourceQueue: queue.value);
      return;
    }

    if (playbackMode.value == PlaybackMode.repeatAll && queue.value.isNotEmpty) {
      final previous = queue.value.last;
      currentIndex.value = queue.value.length - 1;
      currentTrack.value = previous;
      await playTrack(previous, sourceQueue: queue.value);
    }
  }

  Future<void> cyclePlaybackMode() async {
    final modes = PlaybackMode.values;
    final currentIndexMode = modes.indexOf(playbackMode.value);
    final nextMode = modes[(currentIndexMode + 1) % modes.length];
    playbackMode.value = nextMode;
  }

  Future<void> _advanceAfterCompletion() async {
    if (!isPlaying.value && playbackMode.value == PlaybackMode.repeatOne) {
      final current = currentTrack.value;
      if (current != null) {
        await playTrack(current, sourceQueue: queue.value);
      }
      return;
    }

    await nextTrack();
  }

  Future<void> dispose() async {
    _stopPolling();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
  }
}

class PlayerScreen extends StatefulWidget {
  final TrackModel track;
  const PlayerScreen({super.key, required this.track});

  static double sliderValueFor(Duration position, Duration duration) {
    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) {
      return 0.0;
    }

    final raw = position.inMilliseconds.clamp(0, totalMs).toDouble();
    if (raw.isNaN || raw.isInfinite) {
      return 0.0;
    }
    return raw;
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late TrackModel _track;
  final HarmonyAudioController _controller = HarmonyAudioController.instance;

  void _syncFromController() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _track = widget.track;
    if (_controller.currentTrack.value == null || _controller.currentTrack.value!.id != _track.id) {
      _controller.currentTrack.value = _track;
      _controller.position.value = Duration.zero;
      _controller.duration.value = Duration.zero;
    }
    _syncFromController();

    _controller.isPlaying.addListener(_syncFromController);
    _controller.position.addListener(_syncFromController);
    _controller.duration.addListener(_syncFromController);
    _controller.currentTrack.addListener(_syncFromController);
    _controller.errorMessage.addListener(_syncFromController);
    _controller.playbackMode.addListener(_syncFromController);

  }

  Future<void> _togglePlay() async {
    if (_controller.currentTrack.value == null) {
      _controller.currentTrack.value = _track;
    }
    await _controller.togglePlay();
    _syncFromController();
  }

  Future<void> _retryPlay() async {
    _controller.errorMessage.value = null;
    await _controller.playTrack(_track, sourceQueue: _controller.queue.value.isEmpty ? [_track] : _controller.queue.value);
    _syncFromController();
  }

  Future<void> _nextTrack() async {
    await _controller.nextTrack();
    _syncFromController();
  }

  Future<void> _previousTrack() async {
    await _controller.previousTrack();
    _syncFromController();
  }

  Future<void> _cyclePlaybackMode() async {
    await _controller.cyclePlaybackMode();
    _syncFromController();
  }

  @override
  void dispose() {
    _controller.isPlaying.removeListener(_syncFromController);
    _controller.position.removeListener(_syncFromController);
    _controller.duration.removeListener(_syncFromController);
    _controller.currentTrack.removeListener(_syncFromController);
    _controller.errorMessage.removeListener(_syncFromController);
    _controller.playbackMode.removeListener(_syncFromController);
    super.dispose();
  }

  Future<void> _seekTo(Duration value) async {
    await _controller.seek(value);
    _syncFromController();
  }

  Future<void> _showCalibrationSheet() async {
    final bpmController = TextEditingController(text: _track.bpm > 0 ? _track.bpm.toStringAsFixed(0) : '');
    String? selectedKey = _musicKeySignatures.contains(_track.keySignature) ? _track.keySignature : null;

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
                  Text('Song Information', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bpmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'BPM', hintText: 'e.g. 120'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter BPM';
                      final n = int.tryParse(v);
                      if (n == null || n < 1 || n > 300) return 'Enter a BPM from 1 to 300';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedKey,
                    decoration: const InputDecoration(labelText: 'Key Signature'),
                    hint: const Text('Select a key signature'),
                    items: _musicKeySignatures
                        .map((key) => DropdownMenuItem<String>(value: key, child: Text(key)))
                        .toList(),
                    onChanged: (value) => selectedKey = value,
                    validator: (value) => value == null ? 'Select a key signature' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if ((formKey.currentState?.validate() ?? false) && selectedKey != null) {
                            final newBpm = double.parse(bpmController.text);
                            final newKey = selectedKey!;
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
                                  isUserVerified: _track.isUserVerified,
                                );
                                await box.putAt(i, updated.toMap());
                                if (mounted) {
                                  _track = updated;
                                  _controller.currentTrack.value = updated;
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

  Future<void> _showLyricsImport() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LyricsImportSheet(trackId: _track.id, title: _track.title, duration: _controller.duration.value),
    );
    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTrack = _controller.currentTrack.value ?? _track;
    final isPlaying = _controller.isPlaying.value;
    final position = _controller.position.value;
    final duration = _controller.duration.value;
    final error = _controller.errorMessage.value;
    final modeLabel = _controller.playbackMode.value.name;

    return Scaffold(
      appBar: AppBar(title: Text(activeTrack.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // existing UI continues below
            // Insert Add Lyrics button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _showLyricsImport,
                  icon: const Icon(Icons.lyrics),
                  label: const Text('Add lyrics'),
                ),
              ],
            ),
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
                          Text(activeTrack.title, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            'Key: ${activeTrack.keySignature.isEmpty ? 'Not set' : activeTrack.keySignature} • ${activeTrack.bpm > 0 ? '${activeTrack.bpm.toStringAsFixed(0)} BPM' : 'BPM not set'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _previousTrack,
                  icon: const Icon(Icons.skip_previous_rounded),
                  tooltip: 'Previous track',
                ),
                IconButton(
                  onPressed: error == null ? _togglePlay : _retryPlay,
                  icon: Icon(error != null ? Icons.refresh_rounded : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                  tooltip: error != null ? 'Retry' : (isPlaying ? 'Pause' : 'Play'),
                  iconSize: 30,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    padding: EdgeInsets.zero,
                  ),
                ),
                IconButton(
                  onPressed: _nextTrack,
                  icon: const Icon(Icons.skip_next_rounded),
                  tooltip: 'Next track',
                ),
                IconButton(
                  onPressed: _cyclePlaybackMode,
                  icon: Icon(_playbackIcon(_controller.playbackMode.value)),
                  tooltip: modeLabel,
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
                    max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                    value: PlayerScreen.sliderValueFor(position, duration),
                    onChanged: (duration.inMilliseconds > 0)
                        ? (value) async {
                            await _seekTo(Duration(milliseconds: value.toInt()));
                          }
                        : null,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_format(position), style: Theme.of(context).textTheme.bodySmall),
                    Text(_format(duration), style: Theme.of(context).textTheme.bodySmall),
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
                      Text(activeTrack.bpm > 0 ? activeTrack.bpm.toStringAsFixed(0) : 'Not set', style: Theme.of(context).textTheme.titleLarge),
                    ]),
                    ElevatedButton.icon(onPressed: _showCalibrationSheet, icon: const Icon(Icons.tune), label: const Text('Edit'))
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Lyrics view
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  // Widget located in src/lyrics
                  Builder(builder: (ctx) {
                    // insert the LyricsView
                    return Column(children: [
                      const SizedBox(height: 8),
                      LyricsView(trackId: activeTrack.id, title: activeTrack.title),
                    ]);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _playbackIcon(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.normal:
        return Icons.playlist_play_rounded;
      case PlaybackMode.shuffle:
        return Icons.shuffle_rounded;
      case PlaybackMode.repeatAll:
        return Icons.repeat_rounded;
      case PlaybackMode.repeatOne:
        return Icons.repeat_one_rounded;
    }
  }

  String _format(Duration d) {
    if (d.inMilliseconds <= 0) {
      return '--:--';
    }
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
