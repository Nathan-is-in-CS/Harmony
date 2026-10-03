import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/track_model.dart';
import '../theme/harmony_theme.dart';
import '../widgets/harmony_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings_box');
    _tracksBox = Hive.box('tracks_box');
    _settingsBox.delete('keep_ai_suggestions_visible');
    _settingsBox.delete('compact_track_rows');
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
    final tracks = values
        .map((entry) => TrackModel.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
    if (!mounted) return;
    setState(() {
      _trackCount = tracks.length;
      _verifiedCount = tracks.where((track) => track.isUserVerified).length;
      _pendingCount = tracks.length - _verifiedCount;
    });
  }

  void _loadSettings() {
    setState(() {
      _autoLockVerified =
          _settingsBox.get('auto_lock_verified', defaultValue: true) as bool;
      _preserveOfflineCache =
          _settingsBox.get('preserve_offline_cache', defaultValue: true)
              as bool;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async =>
      _settingsBox.put(key, value);

  Future<void> _clearLibrary() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local library?'),
        content: const Text(
          'This removes all cached tracks from this device library. You can rescan them later from the library screen.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
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
        const SnackBar(
          content: Text(
            'Local track cache cleared. Scan again from the library screen.',
          ),
        ),
      );
    }
  }

  Future<void> _resetScanState() async {
    await _settingsBox.put('device_audio_scanned', false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Device scan state reset. Use Scan device audio to scan again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HarmonyHeaderBar(
              title: 'Settings',
              leading: HarmonyHeaderBar.squareButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HarmonySectionLabel('LOCAL LIBRARY · VERIFICATION'),
                    const SizedBox(height: s24),
                    const HarmonySectionLabel('DEVICE PROFILE'),
                    const SizedBox(height: s8),
                    HarmonyCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Harmony offline workspace',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: s8),
                                Text(
                                  'Control local verification settings while staying fully offline.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: s16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const HarmonySectionLabel('TRACKS'),
                              Text(
                                '$_trackCount',
                                style: Theme.of(context).textTheme.displayLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: s16),
                    Row(
                      children: [
                        Expanded(
                          child: _SettingsStatBox(
                            label: 'VERIFIED',
                            value: '$_verifiedCount',
                          ),
                        ),
                        const SizedBox(width: s16),
                        Expanded(
                          child: _SettingsStatBox(
                            label: 'PENDING',
                            value: '$_pendingCount',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: s24),
                    const HarmonySectionLabel('LIBRARY'),
                    const SizedBox(height: s8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearLibrary,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear library'),
                          ),
                        ),
                        const SizedBox(width: s16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _resetScanState,
                            icon: const Icon(Icons.sync),
                            label: const Text('Reset scan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: s24),
                    const HarmonySectionLabel('VERIFICATION'),
                    const SizedBox(height: s8),
                    _ToggleRow(
                      label: 'Auto-lock verified values',
                      value: _autoLockVerified,
                      onChanged: (value) async {
                        setState(() => _autoLockVerified = value);
                        await _saveSetting('auto_lock_verified', value);
                      },
                    ),
                    const SizedBox(height: s8),
                    _ToggleRow(
                      label: 'Preserve offline cache',
                      sublabel:
                          'Keep recent tracks available without rescanning.',
                      value: _preserveOfflineCache,
                      onChanged: (value) async {
                        setState(() => _preserveOfflineCache = value);
                        await _saveSetting('preserve_offline_cache', value);
                      },
                    ),
                    const SizedBox(height: s24),
                    HarmonyCard(
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20),
                          const SizedBox(width: s8),
                          Expanded(
                            child: Text(
                              'All settings remain local to this device. No cloud sync.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
  Widget build(BuildContext context) => HarmonyCard(
    child: Column(
      children: [
        HarmonySectionLabel(label),
        const SizedBox(height: s8),
        Text(value, style: Theme.of(context).textTheme.displayLarge),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(s16),
    decoration: BoxDecoration(
      color: harmonySurface,
      border: Border.all(color: harmonyBorder),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              if (sublabel != null) ...[
                const SizedBox(height: s8),
                Text(sublabel!, style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
        const SizedBox(width: s16),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}
