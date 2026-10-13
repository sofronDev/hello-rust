import 'package:flutter/material.dart';

import '../data/research.dart';
import '../models/profile.dart';
import '../models/program.dart';
import '../services/program_generator.dart';
import '../state/app_state.dart';
import 'format.dart';
import 'programs_page.dart';
import 'research_page.dart';
import 'theme.dart';
import 'widgets.dart';
import 'workout_page.dart';

class ProgramDetailPage extends StatelessWidget {
  const ProgramDetailPage({super.key, required this.program});

  final WorkoutProgram program;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    // Prefer the stored copy (it may contain the user's exercise swaps).
    final p = state.programs.firstWhere((x) => x.id == program.id,
        orElse: () => program);
    final scheme = Theme.of(context).colorScheme;
    final active = state.activeProgramId == p.id;
    final level = p.level ?? state.profile?.level;

    return Scaffold(
      appBar: AppBar(title: Text(p.name, overflow: TextOverflow.ellipsis)),
      body: PageBody(
        maxWidth: 1100,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    GymBadge(p.gymType),
                    if (p.level != null) Pill(p.level!.label),
                    if (p.goal != null) Pill(p.goal!.label),
                  ]),
                  const SizedBox(height: 10),
                  Text(p.description,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Metric(
                          label: 'วัน/สัปดาห์', value: '${p.daysPerWeek}'),
                      _Metric(
                          label: 'นาที/ครั้ง', value: '~${p.averageMinutes}'),
                      _Metric(
                          label: 'รอบ (Deload)',
                          value: '${p.cycleWeeks} สัปดาห์'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (active)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: scheme.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Text('โปรแกรมหลักของคุณ',
                              style: TextStyle(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await state.activateProgram(p);
                          if (context.mounted) {
                            toast(context, 'ตั้ง "${p.name}" เป็นโปรแกรมหลักแล้ว');
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('ใช้โปรแกรมนี้'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SectionTitle('ตารางรายสัปดาห์'),
          _WeekTable(program: p),
          const SectionTitle('รายละเอียดแต่ละวัน'),
          ResponsiveGrid(
            minItemWidth: 420,
            children: [
              for (final d in p.days) DayCard(program: p, day: d),
            ],
          ),
          const SectionTitle('ปริมาณต่อกล้ามเนื้อ / สัปดาห์'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MuscleVolumeBars(
                volume: p.weeklyVolume,
                target: ProgramGenerator.weeklyTarget(
                    level ?? TrainingLevel.novice),
              ),
            ),
          ),
          const SectionTitle('ทำไมจัดแบบนี้ (อ้างอิงงานวิจัย)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  for (final note in p.rationale) _RationaleRow(note),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResearchPage())),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('ดูงานวิจัยทั้งหมด'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _WeekTable extends StatelessWidget {
  const _WeekTable({required this.program});

  final WorkoutProgram program;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            for (var wd = 1; wd <= 7; wd++)
              Expanded(
                child: Builder(builder: (context) {
                  final day = program.dayForWeekday(wd);
                  return Container(
                    margin: const EdgeInsets.all(3),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                    decoration: BoxDecoration(
                      color: day == null
                          ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                          : program.gymType.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(thaiWeekdaysShort[wd - 1],
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          day == null ? 'พัก' : _short(day.name),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 11,
                            color: day == null
                                ? scheme.onSurfaceVariant
                                : program.gymType.textColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  static String _short(String name) => name
      .replaceAll('Full Body ', 'FB ')
      .replaceAll('Upper ', 'บน ')
      .replaceAll('Lower ', 'ล่าง ')
      .replaceAll('Upper', 'บน')
      .replaceAll('Lower', 'ล่าง');
}

class DayCard extends StatelessWidget {
  const DayCard({super.key, required this.program, required this.day});

  final WorkoutProgram program;
  final ProgramDay day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('วัน${thaiWeekdays[day.weekday - 1]}',
                          style: TextStyle(
                              color: program.gymType.textColor(context),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                      Text(day.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(day.focus,
                          style: TextStyle(
                              color: scheme.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
                Pill('~${day.estimatedMinutes} นาที',
                    icon: Icons.timer_outlined, color: scheme.secondary),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            for (final (i, pe) in day.exercises.indexed)
              ExerciseRow(index: i, item: pe, all: day.exercises),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => startWorkout(context, program, day),
              icon: const Icon(Icons.play_arrow),
              label: Text('เริ่ม ${day.name}'),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseRow extends StatelessWidget {
  const ExerciseRow({
    super.key,
    required this.index,
    required this.item,
    required this.all,
  });

  final int index;
  final ProgramExercise item;
  final List<ProgramExercise> all;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = item.exercise;
    final label = blockLabels([for (final x in all) x.superset])[index];
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showExerciseInfo(context, e),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.superset != null
                    ? scheme.tertiaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: item.superset != null
                        ? scheme.onTertiaryContainer
                        : scheme.onSurfaceVariant,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${item.sets} × ${item.repLabel} · RIR ${item.rir} · พัก ${item.restLabel}',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                  if (item.note != null)
                    Text(item.note!,
                        style: TextStyle(color: scheme.tertiary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.info_outline, size: 18, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

class _RationaleRow extends StatelessWidget {
  const _RationaleRow(this.note);

  final String note;

  static final _tag = RegExp(r'\[([A-Z0-9]+)\]');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tags = _tag.allMatches(note).map((m) => m.group(1)!).toList();
    final text = note.replaceAll(_tag, '').trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(Icons.check_circle_outline,
                size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(height: 1.5)),
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final t in tags)
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ResearchPage(highlight: t))),
                            child: Pill(_refLabel(t),
                                icon: Icons.menu_book_outlined,
                                color: scheme.secondary),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _refLabel(String key) {
    for (final r in researchRefs) {
      if (r.key == key) return r.short;
    }
    return key;
  }
}

/// Bottom sheet listing a day's exercises with a start button.
Future<void> showDayPreview(
    BuildContext context, WorkoutProgram program, ProgramDay day) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (sheetContext, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(day.name,
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(day.focus),
          const SizedBox(height: 8),
          for (final (i, pe) in day.exercises.indexed)
            ExerciseRow(index: i, item: pe, all: day.exercises),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(sheetContext);
              startWorkout(context, program, day);
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('เริ่มเวิร์กเอาต์'),
          ),
        ],
      ),
    ),
  );
}
