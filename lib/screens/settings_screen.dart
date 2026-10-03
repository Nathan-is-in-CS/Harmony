import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/track_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Box _settingsBox;
  late final Box _tracksBox;
  int _trackCount = 0;
  int _verifiedCount = 0;
  int _pendingCount = 0;
  bool _autoLockVerified = true;
  bool _preserveOfflineCache = true;
  bool _compactTrackRows = true;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings_box');
    _tracksBox = Hive.box('tracks_box');
    _settingsBox.delete('keep_ai_suggestions_visible');
    _tracksBox.listenable().addListener(_refreshTrackStats);
    _loadSettings();
    _refreshTrackStats();
  }

  @override
  void dispose() {
    _tracksBox.listenable().removeListener(_refreshTrackStats);
    super.dispose();
  }

  void _refreshTrackStats() {
    final values = _tracksBox.values.whereType<Map>();
    final tracks = values.map((entry) => TrackModel.fromMap(Map<String, dynamic>.from(entry))).toList();

    if (!mounted) return;
    setState(() {
      _trackCount = tracks.length;
      _verifiedCount = tracks.where((track) => track.isUserVerified).length;
      _pendingCount = tracks.length - _verifiedCount;
    });
  }

  void _loadSettings() {
    setState(() {
      _autoLockVerified = _settingsBox.get('auto_lock_verified', defaultValue: true) as bool;
      _preserveOfflineCache = _settingsBox.get('preserve_offline_cache', defaultValue: true) as bool;
      _compactTrackRows = _settingsBox.get('compact_track_rows', defaultValue: true) as bool;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  Future<void> _clearLibrary() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local library?'),
        content: const Text('This removes all cached tracks from this device library. You can rescan them later from the library screen.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clear')),
        ],
      ),
    );

    if (shouldClear != true) return;

    await _tracksBox.clear();
    // Do NOT clear lyrics_box: preserve user-entered lyrics across rescans
    await _settingsBox.put('device_audio_scanned', false);
    _refreshTrackStats();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local track cache cleared. Scan again from the library screen.')),
      );
    }
  }

  Future<void> _resetScanState() async {
    await _settingsBox.put('device_audio_scanned', false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device scan state reset. Use Analyze device to scan again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Settings',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'LOCAL STORAGE • ANALYSIS • DISPLAY',
                style: TextStyle(fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F5),
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Harmony\noffline\nworkspace',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.0),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Control how local tracks are cached, locked, and displayed while staying fully offline.',
                            style: TextStyle(fontSize: 18, height: 1.3, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E3E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text('TRACKS', style: TextStyle(fontSize: 18, letterSpacing: 1.2, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Text(_trackCount.toString(), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SettingsStatBox(label: 'VERIFIED', value: _verifiedCount.toString()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SettingsStatBox(label: 'PENDING', value: _pendingCount.toString()),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'STORAGE & SYNC',
                style: TextStyle(fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _StorageRow(
                icon: Icons.storage,
                title: 'Device cache',
                subtitle: '248 MB stored locally',
                trailing: const Icon(Icons.chevron_right),
              ),
              const SizedBox(height: 8),
              _StorageRow(
                icon: Icons.upload_file,
                title: 'Export analysis bundle',
                subtitle: 'Share verified metadata',
                trailing: const Icon(Icons.chevron_right),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Clear library',
                      icon: Icons.delete_outline_rounded,
                      onPressed: _clearLibrary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Reset scan',
                      icon: Icons.sync_rounded,
                      onPressed: _resetScanState,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'ANALYSIS BEHAVIOR',
                style: TextStyle(fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _ToggleRow(
                label: 'Auto-lock verified\nvalues',
                value: _autoLockVerified,
                onChanged: (value) async {
                  setState(() => _autoLockVerified = value);
                  await _saveSetting('auto_lock_verified', value);
                },
              ),
              const SizedBox(height: 12),
              _ToggleRow(
                label: 'Preserve offline cache',
                sublabel: 'Keep recent tracks available without rescanning.',
                value: _preserveOfflineCache,
                onChanged: (value) async {
                  setState(() => _preserveOfflineCache = value);
                  await _saveSetting('preserve_offline_cache', value);
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'DISPLAY PREFERENCES',
                style: TextStyle(fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _ToggleRow(
                label: 'Compact track rows',
                value: _compactTrackRows,
                onChanged: (value) async {
                  setState(() => _compactTrackRows = value);
                  await _saveSetting('compact_track_rows', value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsStatBox extends StatelessWidget {
  final String label;
  final String value;

  const _SettingsStatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 16, letterSpacing: 1.2, color: Colors.black87)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _StorageRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: Icon(icon, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.black54)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.1),
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    sublabel!,
                    style: const TextStyle(fontSize: 18, color: Colors.black54, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 18),
          Switch(
            value: value,
            activeThumbColor: Colors.black,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
