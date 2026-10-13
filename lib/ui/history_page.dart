import 'package:flutter/material.dart';

import '../models/workout_log.dart';
import '../services/progression.dart';
import '../state/app_state.dart';
import 'format.dart';
import 'widgets.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final sessions = state.sessions;
    final groups = <String, List<WorkoutSession>>{};
    for (final s in sessions) {
      groups.putIfAbsent(thaiMonthYear(s.startedAt), () => []).add(s);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการฝึก')),
      body: sessions.isEmpty
          ? const PageBody(children: [
              EmptyState(
                icon: Icons.history,
                title: 'ยังไม่มีประวัติ',
                message: 'เริ่มเวิร์กเอาต์แรกจากหน้า "วันนี้" แล้วผลจะมาแสดงที่นี่',
              ),
            ])
          : PageBody(
              children: [
                for (final entry in groups.entries) ...[
                  SectionTitle(
                    entry.key,
                    top: 8,
                    trailing: Text('${entry.value.length} ครั้ง',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                  for (final s in entry.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SessionTile(session: s),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = session.startedAt;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SessionDetailPage(session: session))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(thaiWeekdaysShort[d.weekday - 1],
                        style: TextStyle(
                            fontSize: 12, color: scheme.onPrimaryContainer)),
                    Text('${d.day}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimaryContainer)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(session.dayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        if (session.deload) ...[
                          const SizedBox(width: 6),
                          Pill('Deload', color: scheme.tertiary),
                        ],
                      ],
                    ),
                    Text(session.programName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(
                      '${fmtDuration(session.duration)} · ${session.completedSets} เซ็ต · ${fmtNumber(session.volumeLoad)} kg',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(session.dayName),
        actions: [
          IconButton(
            tooltip: 'ลบ',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'ลบเวิร์กเอาต์นี้?',
                message: 'ลบแล้วไม่สามารถกู้คืนได้',
                ok: 'ลบ',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              await AppScope.read(context).deleteSession(session.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: PageBody(
        children: [
          Text(
            '${thaiDateLong(session.startedAt)} · ${hhmm(session.startedAt)}',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      icon: Icons.timer_outlined,
                      label: 'เวลา',
                      value: fmtDuration(session.duration))),
              const SizedBox(width: 8),
              Expanded(
                  child: StatTile(
                      icon: Icons.done_all,
                      label: 'เซ็ต',
                      value: '${session.completedSets}')),
              const SizedBox(width: 8),
              Expanded(
                  child: StatTile(
                      icon: Icons.scale_outlined,
                      label: 'น้ำหนักรวม (kg)',
                      value: fmtNumber(session.volumeLoad))),
            ],
          ),
          if (session.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit_note),
                title: Text(session.note),
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final log in session.exercises)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.exercise.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      for (final (i, s) in log.sets.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 56,
                                child: Text('เซ็ต ${i + 1}',
                                    style: TextStyle(
                                        color: scheme.onSurfaceVariant)),
                              ),
                              Text(
                                Progression.tracksWeight(log.exercise) &&
                                        s.weight != null
                                    ? '${fmtKg(s.weight!)} kg × ${s.reps}'
                                    : '${s.reps}${log.exercise.timed ? ' วินาที' : ' ครั้ง'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      if (Progression.bestE1rm(log) case final best?)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '1RM ประมาณ ${fmtKg(Progression.roundLoad(best))} kg',
                            style: TextStyle(
                                color: scheme.primary, fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
