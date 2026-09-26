import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/track_model.dart';

enum PlaybackMode { normal, shuffle, repeatAll, repeatOne }

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
      isPlaying.value = false;
      _stopPolling();
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
      isPlaying.value = false;
      _stopPolling();
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

      isPlaying.value = true;
      _startPolling();
    } catch (e) {
      errorMessage.value = e.toString();
      isPlaying.value = false;
      _stopPolling();
    }
  }

  Future<void> togglePlay() async {
    if (isPlaying.value) {
      await _player.pause();
      isPlaying.value = false;
      _stopPolling();
      return;
    }

    final track = currentTrack.value;
    if (track == null) {
      return;
    }

    if (_player.state == PlayerState.paused) {
      await _player.resume();
      isPlaying.value = true;
      _startPolling();
      return;
    }

    await playTrack(track, sourceQueue: queue.value);
  }

  Future<void> pause() async {
    await _player.pause();
    isPlaying.value = false;
    _stopPolling();
  }

  Future<void> resume() async {
    await _player.resume();
    isPlaying.value = true;
    _startPolling();
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
        isPlaying.value = true;
        _startPolling();
        return;
      case PlaybackMode.shuffle:
        final currentId = currentTrack.value?.id;
        final available = queue.value.where((t) => t.id != currentId).toList();
        if (available.isEmpty) {
          await _player.seek(Duration.zero);
          await _player.resume();
          isPlaying.value = true;
          _startPolling();
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
          isPlaying.value = false;
          _stopPolling();
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
                          Text('Key: ${activeTrack.keySignature} • ${activeTrack.bpm.toStringAsFixed(0)} BPM', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87)),
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
                      Text(activeTrack.bpm.toStringAsFixed(0), style: Theme.of(context).textTheme.titleLarge),
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

  IconData _playbackIcon(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.normal:
        return Icons.play_arrow_rounded;
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
