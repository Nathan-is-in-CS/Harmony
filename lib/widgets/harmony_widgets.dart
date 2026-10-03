import 'package:flutter/material.dart';
import '../theme/harmony_theme.dart';

class HarmonyHeaderBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;

  const HarmonyHeaderBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  static Widget squareButton({
    required Widget icon,
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: icon,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        side: const BorderSide(color: harmonyBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: s16),
      decoration: const BoxDecoration(
        color: harmonyBackground,
        border: Border(bottom: BorderSide(color: harmonyBorder)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: s16)],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: s16), trailing!],
        ],
      ),
    );
  }
}

class HarmonyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const HarmonyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(s16),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: harmonySurface,
      border: Border.all(color: harmonyBorder),
      borderRadius: BorderRadius.circular(4),
    ),
    child: child,
  );
}

class HarmonyMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  const HarmonyMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
  });

  @override
  Widget build(BuildContext context) => HarmonyCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HarmonySectionLabel(label),
        const SizedBox(height: s16),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: value == 'Not set'
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.displayLarge,
        ),
        if (caption != null) ...[
          const SizedBox(height: s8),
          Text(caption!, style: Theme.of(context).textTheme.labelSmall),
        ],
      ],
    ),
  );
}

enum HarmonyStatusVariant { verified, unverified, unprocessed }

class HarmonyStatusBadge extends StatelessWidget {
  final HarmonyStatusVariant variant;
  const HarmonyStatusBadge({super.key, required this.variant});

  @override
  Widget build(BuildContext context) {
    final verified = variant == HarmonyStatusVariant.verified;
    final unprocessed = variant == HarmonyStatusVariant.unprocessed;
    final label = verified
        ? 'VERIFIED'
        : unprocessed
        ? 'UNPROCESSED'
        : 'UNVERIFIED';
    final icon = verified
        ? Icons.lock_outline
        : unprocessed
        ? Icons.schedule
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: s8, vertical: 4),
      decoration: BoxDecoration(
        color: verified ? harmonyPrimary : Colors.transparent,
        border: verified ? null : Border.all(color: harmonyBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: verified ? Colors.white : harmonySecondary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '[ $label ]',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: verified ? Colors.white : harmonySecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class HarmonySectionLabel extends StatelessWidget {
  final String text;
  const HarmonySectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
  );
}
