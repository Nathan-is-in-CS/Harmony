// Simple LRC parser utility

class LyricLine {
  final int timeMs;
  final String text;
  LyricLine({required this.timeMs, required this.text});
}

class ParsedLyrics {
  final List<LyricLine> lines;
  final int offsetMs;
  ParsedLyrics({required this.lines, required this.offsetMs});
}

ParsedLyrics parseLrc(String input) {
  final lines = <LyricLine>[];
  var offset = 0;
  // Normalize line endings
  final normalized = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final parts = normalized.split('\n');
  final timeTagRe = RegExp(r"\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]");
  final offsetRe = RegExp(r"\[offset:([+-]?\d+)\]", caseSensitive: false);

  for (var raw in parts) {
    raw = raw.trim();
    if (raw.isEmpty) continue;
    // metadata offset
    final offMatch = offsetRe.firstMatch(raw);
    if (offMatch != null) {
      offset = int.tryParse(offMatch.group(1) ?? '0') ?? 0;
      continue;
    }

    // collect all time tags
    final matches = timeTagRe.allMatches(raw).toList();
    if (matches.isEmpty) continue;
    // text after last tag
    final last = matches.isNotEmpty ? matches.last : null;
    final textStart = last != null ? last.end : 0;
    final text = raw.substring(textStart).trim();
    for (final m in matches) {
      final min = int.tryParse(m.group(1) ?? '0') ?? 0;
      final sec = int.tryParse(m.group(2) ?? '0') ?? 0;
      final fracRaw = m.group(3) ?? '0';
      var ms = 0;
      if (fracRaw.length == 1) {
        ms = int.parse(fracRaw) * 100;
      } else if (fracRaw.length == 2) {
        ms = int.parse(fracRaw) * 10;
      } else {
        ms = int.parse(fracRaw.padRight(3, '0'));
      }
      final tms = (min * 60 * 1000) + (sec * 1000) + ms;
      lines.add(LyricLine(timeMs: tms, text: text));
    }
  }

  lines.sort((a, b) => a.timeMs.compareTo(b.timeMs));
  return ParsedLyrics(lines: lines, offsetMs: offset);
}

String exportLrc(List<LyricLine> lines, {Map<String, String>? metadata, int? offsetMs}) {
  final sb = StringBuffer();
  if (metadata != null) {
    metadata.forEach((k, v) {
      sb.writeln('[$k:$v]');
    });
  }
  if (offsetMs != null) {
    sb.writeln('[offset:$offsetMs]');
  }
  for (final line in lines) {
    final totalMs = line.timeMs;
    final minutes = (totalMs ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((totalMs % 60000) ~/ 1000).toString().padLeft(2, '0');
    final centi = ((totalMs % 1000) ~/ 10).toString().padLeft(2, '0');
    sb.writeln('[$minutes:$seconds.$centi] ${line.text}');
  }
  return sb.toString();
}
