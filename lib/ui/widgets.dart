import 'package:flutter/material.dart';

import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../models/profile.dart';
import 'format.dart';
import 'theme.dart';

/// Centers content and caps its width so pages read well on tablets and
/// desktops while staying edge-to-edge on phones.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 32),
    this.controller,
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsets padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: EdgeInsets.zero,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing, this.top = 24});

  final String title;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class GymBadge extends StatelessWidget {
  const GymBadge(this.type, {super.key, this.compact = false});

  final GymType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 14, color: type.textColor(context)),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              color: type.textColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color, this.icon});

  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal bars of weekly sets per muscle against a target band.
class MuscleVolumeBars extends StatelessWidget {
  const MuscleVolumeBars({
    super.key,
    required this.volume,
    required this.target,
    this.muscles,
  });

  final Map<Muscle, double> volume;
  final (int, int) target;
  final List<Muscle>? muscles;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (lo, hi) = target;
    final maxV = [
      hi.toDouble() + 2,
      ...volume.values,
    ].reduce((a, b) => a > b ? a : b);
    final list = muscles ?? Muscle.values;
    return Column(
      children: [
        for (final m in list)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(m.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
                Expanded(
                  child: LayoutBuilder(builder: (context, c) {
                    final v = volume[m] ?? 0;
                    final w = c.maxWidth;
                    final inBand = v >= lo && v <= hi;
                    final barColor = v == 0
                        ? scheme.outlineVariant
                        : inBand
                            ? scheme.primary
                            : v < lo
                                ? scheme.tertiary
                                : scheme.error;
                    return SizedBox(
                      height: 14,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // Target band.
                          Positioned(
                            left: w * lo / maxV,
                            width: w * (hi - lo) / maxV,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: w * (v / maxV).clamp(0, 1),
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    fmtSets(volume[m] ?? 0),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(
          'แถบจาง = ช่วงเป้าหมาย $lo–$hi เซ็ต/สัปดาห์ (นับเซ็ตทางอ้อมเป็น 0.5)',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Bottom sheet with exercise details and coaching cue.
Future<void> showExerciseInfo(BuildContext context, Exercise e) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(e.nameTh, style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in e.muscles.entries)
                    Pill(
                      m.value >= 1 ? m.key.label : '${m.key.label} (รอง)',
                      color: m.value >= 1 ? scheme.primary : scheme.secondary,
                    ),
                  Pill(e.pattern.label, color: scheme.tertiary),
                  if (e.lengthened)
                    Pill('เน้นช่วงกล้ามยืด',
                        icon: Icons.straighten, color: const Color(0xFF8E44AD)),
                ],
              ),
              const SizedBox(height: 16),
              Text('วิธีทำ', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(e.cue, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 12),
              Text(
                'อุปกรณ์: ${e.equipment.map((q) => q.label).join(', ')}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String exerciseName(String id) => exerciseById[id]?.name ?? id;

/// Standard block notation: single exercises are A, B, …; exercises in a
/// superset share a letter and are numbered (C1, C2).
List<String> blockLabels(List<String?> supersetTags) {
  final labels = <String>[];
  var block = -1;
  var n = 0;
  String? previous;
  for (final tag in supersetTags) {
    if (tag == null || tag != previous) {
      block++;
      n = 0;
    }
    n++;
    final letter = String.fromCharCode(65 + block);
    labels.add(tag == null ? letter : '$letter$n');
    previous = tag;
  }
  return labels;
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String ok = 'ยืนยัน',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  minimumSize: const Size(64, 44),
                )
              : FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return result ?? false;
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
}
