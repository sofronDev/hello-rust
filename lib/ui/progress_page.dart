import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/exercise_library.dart';
import '../models/profile.dart';
import '../services/program_generator.dart';
import '../services/progression.dart';
import '../state/app_state.dart';
import 'format.dart';
import 'widgets.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String? _exerciseId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final level = state.profile?.level ?? TrainingLevel.novice;

    // Exercises with weight history, most-logged first.
    final counts = <String, int>{};
    for (final s in state.sessions) {
      for (final e in s.exercises) {
        if (Progression.tracksWeight(e.exercise) &&
            Progression.bestE1rm(e) != null) {
          counts[e.exerciseId] = (counts[e.exerciseId] ?? 0) + 1;
        }
      }
    }
    final tracked = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final selected = tracked.contains(_exerciseId)
        ? _exerciseId
        : (tracked.isEmpty ? null : tracked.first);

    return Scaffold(
      appBar: AppBar(title: const Text('สถิติและความก้าวหน้า')),
      body: PageBody(
        maxWidth: 1100,
        children: [
          LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 860;
            final volumeCard = _volumeCard(context, state, level);
            final weeksCard = _weeksCard(context, state);
            if (!wide) {
              return Column(children: [
                volumeCard,
                const SizedBox(height: 12),
                weeksCard,
              ]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: volumeCard),
                const SizedBox(width: 12),
                Expanded(child: weeksCard),
              ],
            );
          }),
          const SectionTitle('ความก้าวหน้ารายท่า (1RM ประมาณ)'),
          if (selected == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: EmptyState(
                  icon: Icons.show_chart,
                  title: 'ยังไม่มีข้อมูลน้ำหนัก',
                  message: 'บันทึกน้ำหนักและจำนวนครั้งในเวิร์กเอาต์ แล้วกราฟจะแสดงที่นี่',
                ),
              ),
            )
          else
            _exerciseCard(context, state, tracked, selected),
          const SectionTitle('น้ำหนักตัว'),
          _BodyWeightCard(state: state),
        ],
      ),
    );
  }

  Widget _volumeCard(BuildContext context, AppState state, TrainingLevel level) {
    final volume = state.muscleSetsInWeek(state.now);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('เซ็ตต่อกล้ามเนื้อ สัปดาห์นี้',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            MuscleVolumeBars(
              volume: volume,
              target: ProgramGenerator.weeklyTarget(level),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeksCard(BuildContext context, AppState state) {
    final scheme = Theme.of(context).colorScheme;
    final thisWeek = startOfWeek(state.now);
    final weeks = [
      for (var i = 7; i >= 0; i--) thisWeek.subtract(Duration(days: 7 * i)),
    ];
    final counts = [for (final w in weeks) state.sessionsInWeek(w).length];
    final target = state.activeProgram?.daysPerWeek ?? 3;
    final maxY = [target, ...counts].reduce((a, b) => a > b ? a : b) + 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('เวิร์กเอาต์ต่อสัปดาห์ (8 สัปดาห์)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('เส้นประ = เป้าหมาย $target ครั้ง/สัปดาห์',
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY.toDouble(),
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: target.toDouble(),
                      color: scheme.onSurfaceVariant,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                    ),
                  ]),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text('${v.toInt()}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) {
                          final w = weeks[v.toInt()];
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              v.toInt() == weeks.length - 1
                                  ? 'นี้'
                                  : '${w.day}/${w.month}',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: scheme.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => scheme.inverseSurface,
                      getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                        'สัปดาห์ ${thaiDate(weeks[group.x], year: false)}\n${rod.toY.toInt()} ครั้ง',
                        TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < weeks.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: counts[i].toDouble(),
                          width: 16,
                          color: i == weeks.length - 1
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: 0.55),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseCard(BuildContext context, AppState state,
      List<String> tracked, String selected) {
    final scheme = Theme.of(context).colorScheme;
    final points = <(DateTime, double, double, int)>[];
    for (final s in state.sessions.reversed) {
      for (final e in s.exercises) {
        if (e.exerciseId != selected) continue;
        double best = 0;
        double w = 0;
        int r = 0;
        for (final set in e.completedSets) {
          final v = Progression.e1rm(set.weight, set.reps) ?? 0;
          if (v > best) {
            best = v;
            w = set.weight!;
            r = set.reps!;
          }
        }
        if (best > 0) points.add((s.startedAt, best, w, r));
      }
    }
    final values = points.map((p) => p.$2);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxV - minV) * 0.2).clamp(2.5, double.infinity);
    final first = points.first.$2;
    final last = points.last.$2;
    final change = first == 0 ? 0 : (last - first) / first * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selected,
                items: [
                  for (final id in tracked)
                    DropdownMenuItem(
                      value: id,
                      child: Text(exerciseById[id]?.name ?? id,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _exerciseId = v),
              ),
            ),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text('ล่าสุด ${fmtKg(Progression.roundLoad(last))} kg',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('สูงสุด ${fmtKg(Progression.roundLoad(maxV))} kg',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                if (points.length > 1)
                  Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% จากครั้งแรก',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: (minV - pad).clamp(0, double.infinity),
                  maxY: maxV + pad,
                  minX: 0,
                  maxX: (points.length - 1).toDouble().clamp(1, double.infinity),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(fmtKg(v.roundToDouble()),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: (points.length / 4).ceilToDouble().clamp(1, 1000),
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= points.length || v != i) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(thaiDate(points[i].$1, year: false),
                                style: TextStyle(
                                    fontSize: 10.5,
                                    color: scheme.onSurfaceVariant)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => scheme.inverseSurface,
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                            '${thaiDate(points[s.x.toInt()].$1)}\n'
                            '${fmtKg(points[s.x.toInt()].$3)} kg × ${points[s.x.toInt()].$4}\n'
                            '1RM ≈ ${fmtKg(Progression.roundLoad(s.y))} kg',
                            TextStyle(
                                color: scheme.onInverseSurface, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (final (i, p) in points.indexed)
                          FlSpot(i.toDouble(), p.$2),
                      ],
                      color: scheme.primary,
                      barWidth: 2,
                      isCurved: false,
                      dotData: FlDotData(
                        getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                          radius: 4,
                          color: scheme.primary,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).cardTheme.color ??
                              scheme.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: scheme.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1RM ประมาณจากสูตร Epley ของเซ็ตที่ดีที่สุดในแต่ละครั้ง — ใช้ดูแนวโน้ม ไม่จำเป็นต้องทดสอบยกสูงสุดจริง',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyWeightCard extends StatelessWidget {
  const _BodyWeightCard({required this.state});

  final AppState state;

  Future<void> _add(BuildContext context) async {
    final controller = TextEditingController(
        text: state.profile == null ? '' : fmtKg(state.profile!.weightKg));
    final kg = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('บันทึกน้ำหนักตัววันนี้'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: const InputDecoration(suffixText: 'kg'),
          onSubmitted: (v) => Navigator.pop(
              context, double.tryParse(v.replaceAll(',', '.'))),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(
                context, double.tryParse(controller.text.replaceAll(',', '.'))),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (kg == null) return;
    if (kg < 30 || kg > 250) {
      if (context.mounted) toast(context, 'น้ำหนักควรอยู่ระหว่าง 30–250 kg');
      return;
    }
    await state.addBodyWeight(kg, state.now);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = state.bodyWeights;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: entries.isEmpty
                      ? Text('ยังไม่มีบันทึก',
                          style: TextStyle(color: scheme.onSurfaceVariant))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${fmtKg(entries.last.kg)} kg',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700)),
                            Text('ล่าสุด ${thaiDate(entries.last.date)}',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _add(context),
                  icon: const Icon(Icons.add),
                  label: const Text('บันทึก'),
                ),
              ],
            ),
            if (entries.length >= 2) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: _weightChart(context, entries.map((e) => (e.date, e.kg)).toList()),
              ),
            ],
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final e in entries.reversed.take(5))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${fmtKg(e.kg)} kg'),
                  subtitle: Text(thaiDateLong(e.date)),
                  trailing: IconButton(
                    tooltip: 'ลบ',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => state.deleteBodyWeight(e),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _weightChart(BuildContext context, List<(DateTime, double)> data) {
    final scheme = Theme.of(context).colorScheme;
    final first = data.first.$1;
    double x(DateTime d) => d.difference(first).inDays.toDouble();
    final values = data.map((e) => e.$2);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minY: minV - 1,
        maxY: maxV + 1,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(v.toStringAsFixed(0),
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${thaiDate(first.add(Duration(days: s.x.toInt())))}\n${fmtKg(s.y)} kg',
                  TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (final (d, kg) in data) FlSpot(x(d), kg)],
            color: scheme.primary,
            barWidth: 2,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 4,
                color: scheme.primary,
                strokeWidth: 2,
                strokeColor: Theme.of(context).cardTheme.color ?? scheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
