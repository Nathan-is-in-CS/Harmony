import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../src/lyrics/lrc_parser.dart';
import '../theme/harmony_theme.dart';

class LyricsImportSheet extends StatefulWidget {
  final String trackId;
  final String title;
  final Duration duration;
  const LyricsImportSheet({
    super.key,
    required this.trackId,
    required this.title,
    required this.duration,
  });

  @override
  State<LyricsImportSheet> createState() => _LyricsImportSheetState();
}

class _LyricsImportSheetState extends State<LyricsImportSheet> {
  final TextEditingController _controller = TextEditingController();
  // _isSynced is unused; remove to avoid analyzer warnings.

  static const externalSites = [
    'https://lrclib.net',
    'https://lyrics.simpmusic.org',
    'https://lyricsify.com',
  ];

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() {
        _controller.text = data!.text!;
      });
    }
  }

  Future<void> _importFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['lrc', 'txt'],
      );
      if (files.isEmpty) return;
      final path = files.single.path;
      if (path == null) return;
      final file = File(path);
      var content = await file.readAsString();
      if (!mounted) return;
      setState(() => _controller.text = content);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to read file: $e')));
    }
  }

  Future<void> _openSite(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No web browser is available on this device.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the external site: $e')),
        );
      }
    }
  }

  Future<void> _saveLyrics() async {
    final content = _controller.text;
    final parsed = parseLrc(content);
    final box = Hive.box('lyrics_box');
    if (parsed.lines.isEmpty) {
      await box.put(widget.trackId, {
        'lines': [],
        'synced': false,
        'offset': 0,
        'plain': content,
      });
    } else {
      final serial = parsed.lines
          .map((l) => {'timeMs': l.timeMs, 'text': l.text})
          .toList();
      await box.put(widget.trackId, {
        'lines': serial,
        'synced': true,
        'offset': parsed.offsetMs,
        'plain': content,
      });
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(s16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add lyrics for: ${widget.title} (${widget.duration.inSeconds}s)',
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: s16),
              child: Text(
                'On lrclib.net, open your song, tap Copy as → Synced lyrics (LRC), then paste here.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(s16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.paste),
                      label: const Text('Paste'),
                    ),
                    const SizedBox(width: s8),
                    OutlinedButton.icon(
                      onPressed: _importFile,
                      icon: const Icon(Icons.file_open),
                      label: const Text('Import .lrc file'),
                    ),
                    const SizedBox(width: s8),
                    PopupMenuButton<String>(
                      itemBuilder: (ctx) => externalSites
                          .map((s) => PopupMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onSelected: (v) => _openSite(v),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new),
                          const SizedBox(width: s8),
                          const Text('External sites'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: s16),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(s16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: s8),
                  FilledButton(
                    onPressed: _saveLyrics,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
