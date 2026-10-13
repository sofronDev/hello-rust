import 'package:flutter/material.dart';

import '../models/program.dart';
import '../state/app_state.dart';
import 'format.dart';
import 'program_detail_page.dart';
import 'widgets.dart';
import 'workout_page.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final program = state.activeProgram;
    final now = state.now;
    final name = state.profile?.name ?? state.account?.name ?? '';

    return Scaffold(
      body: SafeArea(
        child: PageBody(
          children: [
            const SizedBox(height: 8),
            Text(thaiDateLong(now),
                style: TextStyle(color: scheme.onSurfaceVariant)),
            Text(
              'สวัสดี $name',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (program == null)
              EmptyState(
                icon: Icons.calendar_view_week,
                title: 'ยังไม่ได้เลือกโปรแกรม',
                message: 'เลือกโปรแกรมที่จัดให้คุณ หรือโปรแกรมเบื้องต้น',
                action: FilledButton(
                  onPressed: () => state.requestTab(1),
                  child: const Text('ไปที่โปรแกรม'),
                ),
              )
            else ...[
              _ProgramHeader(program: program),
              const SizedBox(height: 12),
              _WeekStrip(program: program),
              const SizedBox(height: 12),
              _TodayCard(program: program),
              const SizedBox(height: 12),
              _Stats(program: program),
              SectionTitle('วันฝึกในโปรแกรม',
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProgramDetailPage(program: program),
                      ),
                    ),
                    child: const Text('ดูทั้งหมด'),
                  )),
              for (final day in program.days)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DayTile(program: program, day: day),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgramHeader extends StatelessWidget {
  const _ProgramHeader({required this.program});

  final WorkoutProgram program;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProgramDetailPage(program: program))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        GymBadge(program.gymType),
                        Pill('สัปดาห์ ${state.cycleWeek}/${program.cycleWeeks}',
                            icon: Icons.calendar_month),
                        if (state.isDeloadWeek)
                          Pill('Deload',
                              icon: Icons.spa_outlined, color: scheme.tertiary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(program.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
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

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.program});

  final WorkoutProgram program;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final start = startOfWeek(state.now);
    final doneDays = {
      for (final s in state.sessionsInWeek(state.now)) s.startedAt.weekday,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Builder(builder: (context) {
                  final date = start.add(Duration(days: i));
                  final weekday = i + 1;
                  final planned = program.dayForWeekday(weekday) != null;
                  final done = doneDays.contains(weekday);
                  final today = weekday == state.now.weekday;
                  return Column(
                    children: [
                      Text(thaiWeekdaysShort[i],
                          style: TextStyle(
                            fontSize: 12,
                            color: today
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            fontWeight:
                                today ? FontWeight.w700 : FontWeight.w400,
                          )),
                      const SizedBox(height: 6),
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? scheme.primary
                              : planned
                                  ? scheme.primaryContainer
                                  : Colors.transparent,
                          border: today
                              ? Border.all(color: scheme.primary, width: 2)
                              : null,
                        ),
                        child: done
                            ? Icon(Icons.check,
                                size: 18, color: scheme.onPrimary)
                            : Text('${date.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: planned
                                      ? scheme.onPrimaryContainer
                                      : scheme.onSurfaceVariant,
                                )),
                      ),
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.program});

  final WorkoutProgram program;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final active = state.activeSession;

    if (active != null) {
      return _HeroCard(
        color: scheme.tertiaryContainer,
        onColor: scheme.onTertiaryContainer,
        icon: Icons.timer_outlined,
        label: 'กำลังฝึกอยู่',
        title: active.dayName,
        subtitle:
            'ทำไปแล้ว ${active.completedSets}/${active.plannedSets} เซ็ต · เริ่ม ${hhmm(active.startedAt)}',
        button: FilledButton.icon(
          onPressed: () => openWorkout(context),
          icon: const Icon(Icons.play_arrow),
          label: const Text('กลับไปบันทึก'),
        ),
      );
    }

    final today = state.todaysDay;
    final doneToday = state.sessions
        .where((s) => dateOnly(s.startedAt) == dateOnly(state.now))
        .firstOrNull;

    if (doneToday != null) {
      final s = doneToday;
      return _HeroCard(
        color: scheme.primaryContainer,
        onColor: scheme.onPrimaryContainer,
        icon: Icons.emoji_events_outlined,
        label: 'วันนี้ฝึกเสร็จแล้ว',
        title: s.dayName,
        subtitle:
            '${s.completedSets} เซ็ต · ${fmtDuration(s.duration)} · ${fmtNumber(s.volumeLoad)} kg — พักฟื้นให้เต็มที่',
      );
    }

    if (today != null) {
      final deload = state.isDeloadWeek;
      return _HeroCard(
        color: scheme.primary,
        onColor: scheme.onPrimary,
        icon: Icons.fitness_center,
        label: deload ? 'วันนี้ · Deload (ลดเซ็ตครึ่งหนึ่ง)' : 'วันนี้',
        title: today.name,
        subtitle:
            '${today.focus}\n${today.exercises.length} ท่า · ${today.totalSets} เซ็ต · ~${today.estimatedMinutes} นาที',
        button: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.onPrimary,
            foregroundColor: scheme.primary,
          ),
          onPressed: () => startWorkout(context, program, today),
          icon: const Icon(Icons.play_arrow),
          label: const Text('เริ่มเวิร์กเอาต์'),
        ),
      );
    }

    final next = state.nextDay;
    return _HeroCard(
      color: scheme.secondaryContainer,
      onColor: scheme.onSecondaryContainer,
      icon: Icons.self_improvement,
      label: 'วันพัก',
      title: 'พักฟื้นและเคลื่อนไหวเบา ๆ',
      subtitle:
          'เดินเร็วหรือคาร์ดิโอเบา 20–40 นาที ยืดเหยียด และนอนให้พอ 7–9 ชม. ช่วยให้ฟื้นตัวพร้อมฝึกครั้งถัดไป',
      button: next == null
          ? null
          : OutlinedButton.icon(
              onPressed: () => startWorkout(context, program, next),
              icon: const Icon(Icons.play_arrow),
              label: Text('อยากฝึกวันนี้? เริ่ม ${next.name}'),
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.color,
    required this.onColor,
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
    this.button,
  });

  final Color color;
  final Color onColor;
  final IconData icon;
  final String label;
  final String title;
  final String subtitle;
  final Widget? button;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: onColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: onColor.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  color: onColor, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: onColor.withValues(alpha: 0.9), height: 1.45)),
          if (button != null) ...[
            const SizedBox(height: 14),
            button!,
          ],
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.program});

  final WorkoutProgram program;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final week = state.sessionsInWeek(state.now);
    final volume = week.fold<double>(0, (a, s) => a + s.volumeLoad);
    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: Icons.check_circle_outline,
            label: 'สัปดาห์นี้',
            value: '${week.length}/${program.daysPerWeek}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            icon: Icons.local_fire_department_outlined,
            color: const Color(0xFFE07B39),
            label: 'สัปดาห์ติดกัน',
            value: '${state.weekStreak}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            icon: Icons.scale_outlined,
            color: const Color(0xFF5B5BD6),
            label: 'น้ำหนักรวม (kg)',
            value: fmtNumber(volume),
          ),
        ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.program, required this.day});

  final WorkoutProgram program;
  final ProgramDay day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(thaiWeekdaysShort[day.weekday - 1],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        title: Text(day.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${day.exercises.length} ท่า · ${day.totalSets} เซ็ต · ~${day.estimatedMinutes} นาที'),
        trailing: IconButton.filledTonal(
          tooltip: 'เริ่ม ${day.name}',
          icon: const Icon(Icons.play_arrow),
          onPressed: () => startWorkout(context, program, day),
        ),
        onTap: () => showDayPreview(context, program, day),
      ),
    );
  }
}
