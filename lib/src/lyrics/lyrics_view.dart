import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'lrc_parser.dart';
import '../../screens/player_screen.dart' show HarmonyAudioController;

class LyricsView extends StatefulWidget {
  final String trackId;
  final String title;
  const LyricsView({super.key, required this.trackId, required this.title});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final _scroll = ScrollController();
  final HarmonyAudioController _controller = HarmonyAudioController.instance;
  List<LyricLine> _lines = [];
  bool _synced = false;
  int _offsetMs = 0;
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
    _controller.position.addListener(_onPosition);
    _controller.currentTrack.addListener(_onTrackChange);
  }

  @override
  void dispose() {
    _controller.position.removeListener(_onPosition);
    _controller.currentTrack.removeListener(_onTrackChange);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackId != widget.trackId) {
      _loadLyrics();
    }
  }

  void _onTrackChange() {
    // Clear immediately. The parent will rebuild with the new trackId and
    // didUpdateWidget will then load that track's lyrics.
    _clearLyrics();
  }

  void _clearLyrics() {
    _lines = [];
    _synced = false;
    _offsetMs = 0;
    _activeIndex = -1;
    if (mounted) setState(() {});
  }

  void _loadLyrics() {
    _clearLyrics();
    final box = Hive.box('lyrics_box');
    final raw = box.get(widget.trackId);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final linesRaw = map['lines'] as List<dynamic>?;
      final offset = (map['offset'] is int) ? map['offset'] as int : 0;
      if (linesRaw != null && linesRaw.isNotEmpty) {
        _lines = linesRaw.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return LyricLine(timeMs: (m['timeMs'] as int?) ?? 0, text: (m['text'] as String?) ?? '');
        }).toList();
        _synced = true;
        _offsetMs = offset;
      } else {
        // plain lyrics may be stored as 'plain'
        _offsetMs = offset;
      }
    }
    _activeIndex = -1;
    if (mounted) setState(() {});
  }

  void _onPosition() {
    if (!_synced || _lines.isEmpty) return;
    final pos = _controller.position.value.inMilliseconds;
    final effective = pos - _offsetMs;
    var low = 0, high = _lines.length - 1, ans = -1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (_lines[mid].timeMs <= effective) {
        ans = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    if (ans != _activeIndex) {
      _activeIndex = ans;
      if (_activeIndex >= 0) {
        // scroll into view
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          final itemExtent = 56.0;
          final offset = (_activeIndex * itemExtent) - (itemExtent * 2);
          _scroll.animateTo(offset.clamp(0.0, _scroll.position.maxScrollExtent), duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        });
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _seekToLine(int index) async {
    if (index < 0 || index >= _lines.length) return;
    final targetMs = _lines[index].timeMs + _offsetMs;
    await _controller.seek(Duration(milliseconds: targetMs));
  }

  Future<void> _nudgeOffset(int deltaMs) async {
    _offsetMs += deltaMs;
    final box = Hive.box('lyrics_box');
    final raw = box.get(widget.trackId) as Map?;
    final map = raw != null ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    map['offset'] = _offsetMs;
    await box.put(widget.trackId, map);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_synced && _lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: const Text('No synced lyrics available.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_synced ? 'Synced Lyrics' : 'Lyrics', style: Theme.of(context).textTheme.titleSmall),
            Row(children: [
              IconButton(onPressed: () => _nudgeOffset(-500), icon: const Icon(Icons.remove)),
              Text('${(_offsetMs / 1000).toStringAsFixed(2)}s'),
              IconButton(onPressed: () => _nudgeOffset(500), icon: const Icon(Icons.add)),
            ])
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView.builder(
            controller: _scroll,
            itemCount: _lines.length,
            itemBuilder: (context, index) {
              final line = _lines[index];
              final isActive = index == _activeIndex;
              return InkWell(
                onTap: _synced ? () => _seekToLine(index) : null,
                child: Container(
                  // `withOpacity` is deprecated; use `withAlpha` for equivalent effect.
                  color: isActive ? Theme.of(context).colorScheme.primary.withAlpha((0.12 * 255).round()) : null,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 76, child: Text(_formatMs(line.timeMs), style: TextStyle(color: Colors.black54, fontSize: 12))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(line.text, style: TextStyle(fontSize: isActive ? 16 : 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatMs(int ms) {
    final total = ms.clamp(0, 24 * 3600 * 1000);
    final m = (total ~/ 60000).toString().padLeft(2, '0');
    final s = ((total % 60000) ~/ 1000).toString().padLeft(2, '0');
    final c = ((total % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$c';
  }
}
