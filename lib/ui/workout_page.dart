import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/preset_programs.dart';
import '../models/exercise.dart';
import '../models/profile.dart';
import '../models/program.dart';
import '../models/workout_log.dart';
import '../services/alert/alert.dart';
import '../services/program_generator.dart';
import '../services/progression.dart';
import '../state/app_state.dart';
import 'format.dart';
import 'widgets.dart';

Future<void> openWorkout(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => const WorkoutPage()),
  );
}

/// Starts [day] (asking first if another workout is in progress).
Future<void> startWorkout(
    BuildContext context, WorkoutProgram program, ProgramDay day) async {
  final state = AppScope.read(context);
  final current = state.activeSession;
  if (current != null) {
    if (current.dayId == day.id) return openWorkout(context);
    final ok = await confirm(
      context,
      title: 'มีเวิร์กเอาต์ค้างอยู่',
      message:
          '"${current.dayName}" ยังไม่จบ (${current.completedSets} เซ็ต) ต้องการทิ้งแล้วเริ่ม "${day.name}" ใหม่หรือไม่?',
      ok: 'ทิ้งและเริ่มใหม่',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
  }
  state.startSession(program, day);
  return openWorkout(context);
}

WorkoutProgram? _programById(AppState state, String id) {
  for (final p in [...state.programs, ...presetPrograms]) {
    if (p.id == id) return p;
  }
  return null;
}

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final _rest = ValueNotifier<_RestState?>(null);

  @override
  void dispose() {
    _rest.dispose();
    super.dispose();
  }

  void _startRest(int seconds) {
    _rest.value = _RestState(
      end: DateTime.now().add(Duration(seconds: seconds)),
      total: seconds,
    );
  }

  void _onSetCompleted(WorkoutSession session, ExerciseLog log, int setIndex) {
    primeAlert();
    HapticFeedback.mediumImpact();
    // Superset: go straight to the partner exercise, rest after the last.
    if (log.superset != null) {
      final group =
          session.exercises.where((e) => e.superset == log.superset).toList();
      if (group.last != log) {
        final partner = group[group.indexOf(log) + 1];
        _rest.value = null;
        toast(context, 'ซูเปอร์เซ็ต: ต่อด้วย ${partner.exercise.name}');
        return;
      }
    }
    _startRest(log.restSec);
  }

  Future<void> _finish(WorkoutSession session) async {
    final state = AppScope.read(context);
    final done = session.completedSets;
    if (done == 0) {
      final discard = await confirm(
        context,
        title: 'ยังไม่มีเซ็ตที่ทำเสร็จ',
        message: 'ต้องการยกเลิกเวิร์กเอาต์นี้หรือไม่?',
        ok: 'ยกเลิกเวิร์กเอาต์',
        destructive: true,
      );
      if (discard) {
        await state.discardActiveSession();
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }
    final remaining = session.plannedSets - done;
    final ok = await confirm(
      context,
      title: 'จบเวิร์กเอาต์?',
      message: remaining > 0
          ? 'ยังมี $remaining เซ็ตที่ยังไม่ได้ติ๊ก ระบบจะบันทึกเฉพาะ $done เซ็ตที่ทำเสร็จ'
          : 'บันทึก $done เซ็ต ทำได้ดีมาก!',
      ok: 'บันทึก',
    );
    if (!ok || !mounted) return;
    final result = await state.finishActiveSession();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => _SummaryDialog(result: result),
    );
    navigator.pop();
  }

  Future<void> _discard() async {
    final state = AppScope.read(context);
    final ok = await confirm(
      context,
      title: 'ทิ้งเวิร์กเอาต์นี้?',
      message: 'ข้อมูลของเวิร์กเอาต์นี้จะไม่ถูกบันทึก',
      ok: 'ทิ้ง',
      destructive: true,
    );
    if (!ok) return;
    await state.discardActiveSession();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.activeSession;
    if (session == null) {
      return const Scaffold(body: Center(child: Text('ไม่มีเวิร์กเอาต์ที่กำลังทำ')));
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'ย่อ (เวิร์กเอาต์ยังดำเนินอยู่)',
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.dayName),
            _ElapsedClock(start: session.startedAt),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(72, 40)),
              onPressed: () => _finish(session),
              child: const Text('จบ'),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: PageBody(
          maxWidth: 720,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 120),
          children: [
            if (session.deload)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'สัปดาห์ Deload: เซ็ตลดลงครึ่งหนึ่ง ใช้น้ำหนักเดิมแต่หยุดห่าง failure มากขึ้น (RIR 3–4)',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            _ProgressHeader(session: session),
            const SizedBox(height: 10),
            for (final (i, log) in session.exercises.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExerciseCard(
                  key: ObjectKey(log),
                  session: session,
                  log: log,
                  index: i,
                  onSetCompleted: (setIndex) =>
                      _onSetCompleted(session, log, setIndex),
                ),
              ),
            TextFormField(
              initialValue: session.note,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'โน้ต (ความรู้สึก, อาการเจ็บ, ฯลฯ)',
                prefixIcon: Icon(Icons.edit_note),
              ),
              onChanged: (v) {
                session.note = v;
                state.saveActiveSession();
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _finish(session),
              icon: const Icon(Icons.flag),
              label: const Text('จบและบันทึกเวิร์กเอาต์'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              onPressed: _discard,
              icon: const Icon(Icons.delete_outline),
              label: const Text('ทิ้งเวิร์กเอาต์นี้'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<_RestState?>(
        valueListenable: _rest,
        builder: (context, rest, _) => rest == null
            ? const SizedBox.shrink()
            : _RestBar(
                rest: rest,
                onAdjust: (delta) {
                  final end = rest.end.add(Duration(seconds: delta));
                  _rest.value = _RestState(
                      end: end,
                      total: (rest.total + delta).clamp(1, 3600));
                },
                onSkip: () => _rest.value = null,
              ),
      ),
    );
  }
}

class _RestState {
  const _RestState({required this.end, required this.total});

  final DateTime end;
  final int total;
}

class _ElapsedClock extends StatefulWidget {
  const _ElapsedClock({required this.start});

  final DateTime start;

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      fmtClock(DateTime.now().difference(widget.start)),
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _RestBar extends StatefulWidget {
  const _RestBar({
    required this.rest,
    required this.onAdjust,
    required this.onSkip,
  });

  final _RestState rest;
  final ValueChanged<int> onAdjust;
  final VoidCallback onSkip;

  @override
  State<_RestBar> createState() => _RestBarState();
}

class _RestBarState extends State<_RestBar> {
  late final Timer _timer;
  bool _alerted = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final remaining = widget.rest.end.difference(DateTime.now());
      if (remaining.isNegative && !_alerted) {
        _alerted = true;
        restDoneAlert();
        HapticFeedback.heavyImpact();
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(_RestBar old) {
    super.didUpdateWidget(old);
    if (old.rest.end != widget.rest.end &&
        widget.rest.end.isAfter(DateTime.now())) {
      _alerted = false;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = widget.rest.end.difference(DateTime.now());
    final over = remaining.isNegative;
    final secs = remaining.inSeconds.abs();
    final progress =
        over ? 1.0 : 1 - remaining.inMilliseconds / (widget.rest.total * 1000);
    final bg = over ? scheme.primary : scheme.inverseSurface;
    final fg = over ? scheme.onPrimary : scheme.onInverseSurface;
    return Material(
      color: bg,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 4,
              backgroundColor: fg.withValues(alpha: 0.15),
              color: over ? fg : scheme.primary,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(over ? Icons.notifications_active : Icons.hourglass_bottom,
                      color: fg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(over ? 'หมดเวลาพัก — เซ็ตถัดไป!' : 'พัก',
                            style: TextStyle(color: fg, fontSize: 12.5)),
                        Text(
                          '${over ? '+' : ''}${fmtClock(Duration(seconds: secs))}',
                          style: TextStyle(
                            color: fg,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: fg),
                    onPressed: () => widget.onAdjust(-15),
                    child: const Text('−15'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: fg),
                    onPressed: () => widget.onAdjust(15),
                    child: const Text('+15'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: fg),
                    onPressed: widget.onSkip,
                    child: Text(over ? 'ปิด' : 'ข้าม'),
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

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = session.completedSets;
    final total = session.plannedSets;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$done/$total เซ็ต',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({
    super.key,
    required this.session,
    required this.log,
    required this.index,
    required this.onSetCompleted,
  });

  final WorkoutSession session;
  final ExerciseLog log;
  final int index;
  final ValueChanged<int> onSetCompleted;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  ExerciseLog get log => widget.log;

  void _changed() {
    AppScope.read(context).saveActiveSession();
    setState(() {});
  }

  double? _weightAbove(int index) {
    for (var j = index - 1; j >= 0; j--) {
      if (log.sets[j].weight != null) return log.sets[j].weight;
    }
    return null;
  }

  /// A weight typed into one set carries down to the following unfinished
  /// sets that were blank or still held the old value.
  void _carryWeight(int index, double? old, double? value) {
    for (var j = index + 1; j < log.sets.length; j++) {
      final s = log.sets[j];
      if (s.done) continue;
      if (s.weight == null || s.weight == old) s.weight = value;
    }
    _changed();
  }

  Future<void> _menu(String action) async {
    final state = AppScope.read(context);
    switch (action) {
      case 'info':
        await showExerciseInfo(context, log.exercise);
      case 'swap':
        await _swap();
      case 'add':
        final last = log.sets.isEmpty ? null : log.sets.last;
        log.sets.add(SetLog(weight: last?.weight));
        state.activeSessionChanged();
        setState(() {});
      case 'remove':
        if (log.sets.isNotEmpty) {
          log.sets.removeLast();
          state.activeSessionChanged();
          setState(() {});
        }
    }
  }

  Future<void> _swap() async {
    final state = AppScope.read(context);
    final program = _programById(state, widget.session.programId);
    final equipment = program?.equipment ?? Equipment.values.toSet();
    final options = ProgramGenerator.candidates(
            log.exercise.pattern, state.profile, equipment)
        .where((e) => e.id != log.exerciseId)
        .toList();
    var saveToProgram = program != null && !program.isPreset;
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('เปลี่ยนท่า (${log.exercise.pattern.label})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (program != null && !program.isPreset)
                SwitchListTile(
                  value: saveToProgram,
                  onChanged: (v) => setSheet(() => saveToProgram = v),
                  title: const Text('ใช้ท่านี้ในโปรแกรมครั้งต่อไปด้วย'),
                ),
              if (options.isEmpty)
                const ListTile(title: Text('ไม่มีท่าทดแทนสำหรับอุปกรณ์นี้')),
              for (final e in options)
                ListTile(
                  title: Text(e.name),
                  subtitle: Text(
                      '${e.nameTh} · ${e.equipment.map((q) => q.label).join(', ')}'),
                  onTap: () => Navigator.pop(context, e),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final oldId = log.exerciseId;
    state.swapExercise(log, picked);
    if (saveToProgram && program != null) {
      final days = [
        for (final d in program.days)
          d.id == widget.session.dayId
              ? d.copyWith(exercises: [
                  for (final pe in d.exercises)
                    pe.exerciseId == oldId
                        ? pe.copyWith(exerciseId: picked.id)
                        : pe,
                ])
              : d,
      ];
      await state.updateProgram(program.copyWith(days: days));
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final scheme = Theme.of(context).colorScheme;
    final e = log.exercise;
    final suggestion = state.suggestionFor(log);
    final last = suggestion.last;
    final tracksWeight = Progression.tracksWeight(e);
    final allDone = log.sets.isNotEmpty && log.sets.every((s) => s.done);

    final label = blockLabels(
        [for (final x in widget.session.exercises) x.superset])[widget.index];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: allDone
              ? scheme.primary.withValues(alpha: 0.6)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: allDone
                        ? scheme.primary
                        : log.superset != null
                            ? scheme.tertiaryContainer
                            : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: allDone
                      ? Icon(Icons.check, size: 18, color: scheme.onPrimary)
                      : Text(label,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => showExerciseInfo(context, e),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(
                          '${log.sets.length} × ${log.repMin}–${log.repMax}${e.timed ? ' วิ' : ''} · RIR ${log.rir} · พัก ${log.restSec ~/ 60}:${(log.restSec % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                              fontSize: 12.5, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'ตัวเลือก',
                  onSelected: _menu,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'info', child: Text('วิธีทำท่านี้')),
                    PopupMenuItem(value: 'swap', child: Text('เปลี่ยนท่า')),
                    PopupMenuItem(value: 'add', child: Text('เพิ่มเซ็ต')),
                    PopupMenuItem(value: 'remove', child: Text('ลบเซ็ตสุดท้าย')),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.trending_up, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(suggestion.text,
                        style: TextStyle(fontSize: 12.5, color: scheme.primary)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: Row(
                children: [
                  const SizedBox(width: 30, child: _Head('เซ็ต')),
                  const Expanded(flex: 3, child: _Head('ครั้งก่อน')),
                  Expanded(
                      flex: 3, child: _Head(tracksWeight ? 'kg' : 'แรงต้าน')),
                  Expanded(flex: 3, child: _Head(e.timed ? 'วินาที' : 'ครั้ง')),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            for (final (i, s) in log.sets.indexed)
              _SetRow(
                key: ObjectKey(s),
                index: i,
                set: s,
                previous: last != null && i < last.sets.length
                    ? last.sets[i]
                    : null,
                fallbackWeight: _weightAbove(i),
                repHint: '${log.repMin}–${log.repMax}',
                tracksWeight: tracksWeight,
                onChanged: _changed,
                onWeightChanged: (old, value) => _carryWeight(i, old, value),
                onCompleted: () {
                  state.activeSessionChanged();
                  setState(() {});
                  widget.onSetCompleted(i);
                },
                onUncompleted: () {
                  state.activeSessionChanged();
                  setState(() {});
                },
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _menu('add'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มเซ็ต'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

class _SetRow extends StatefulWidget {
  const _SetRow({
    super.key,
    required this.index,
    required this.set,
    required this.previous,
    required this.fallbackWeight,
    required this.repHint,
    required this.tracksWeight,
    required this.onChanged,
    required this.onWeightChanged,
    required this.onCompleted,
    required this.onUncompleted,
  });

  final int index;
  final SetLog set;
  final SetLog? previous;

  /// Weight of the nearest set above, used when this one is left blank.
  final double? fallbackWeight;
  final String repHint;
  final bool tracksWeight;
  final VoidCallback onChanged;
  final void Function(double? old, double? value) onWeightChanged;
  final VoidCallback onCompleted;
  final VoidCallback onUncompleted;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  final _repsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(
        text: widget.set.weight == null ? '' : fmtKg(widget.set.weight!));
    _reps = TextEditingController(
        text: widget.set.reps == null ? '' : '${widget.set.reps}');
  }

  @override
  void didUpdateWidget(_SetRow old) {
    super.didUpdateWidget(old);
    // Weight may be replaced externally (exercise swap).
    final w = widget.set.weight == null ? '' : fmtKg(widget.set.weight!);
    if (!widget.set.done && _weight.text != w &&
        double.tryParse(_weight.text) != widget.set.weight) {
      _weight.text = w;
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  void _toggle() {
    final s = widget.set;
    if (s.done) {
      s.done = false;
      setState(() {});
      widget.onUncompleted();
      return;
    }
    if (s.reps == null || s.reps == 0) {
      final prev = widget.previous?.reps;
      if (prev == null) {
        _repsFocus.requestFocus();
        toast(context, 'ใส่จำนวนครั้งก่อนติ๊ก');
        return;
      }
      s.reps = prev;
      _reps.text = '$prev';
    }
    if (widget.tracksWeight && s.weight == null) {
      s.weight = widget.fallbackWeight ?? widget.previous?.weight;
      if (s.weight != null) _weight.text = fmtKg(s.weight!);
    }
    s.done = true;
    FocusScope.of(context).unfocus();
    setState(() {});
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = widget.set;
    final p = widget.previous;
    final prevText = p == null
        ? '—'
        : widget.tracksWeight && p.weight != null
            ? '${fmtKg(p.weight!)}×${p.reps ?? '-'}'
            : '${p.reps ?? '-'}';

    InputDecoration deco(String hint) => InputDecoration(
          isDense: true,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          filled: true,
          fillColor: s.done
              ? scheme.primaryContainer.withValues(alpha: 0.4)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 4, right: 4),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: s.done ? scheme.primary.withValues(alpha: 0.07) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('${widget.index + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 3,
            child: Text(prevText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: widget.tracksWeight
                  ? TextField(
                      controller: _weight,
                      textAlign: TextAlign.center,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: deco(p?.weight == null ? 'kg' : fmtKg(p!.weight!)),
                      onChanged: (v) {
                        final old = s.weight;
                        s.weight = double.tryParse(v.replaceAll(',', '.'));
                        widget.onWeightChanged(old, s.weight);
                      },
                    )
                  : Text('ตัวเอง',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: TextField(
                controller: _reps,
                focusNode: _repsFocus,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: deco(p?.reps?.toString() ?? widget.repHint),
                onChanged: (v) {
                  s.reps = int.tryParse(v);
                  widget.onChanged();
                },
                onSubmitted: (_) => _toggle(),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: s.done ? 'ยกเลิกติ๊ก' : 'ทำเซ็ตนี้เสร็จ',
              onPressed: _toggle,
              style: IconButton.styleFrom(
                backgroundColor:
                    s.done ? scheme.primary : scheme.surfaceContainerHighest,
                foregroundColor:
                    s.done ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              icon: const Icon(Icons.check),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDialog extends StatelessWidget {
  const _SummaryDialog({required this.result});

  final FinishResult result;

  @override
  Widget build(BuildContext context) {
    final s = result.session;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.emoji_events, color: scheme.primary, size: 40),
      title: const Text('บันทึกเรียบร้อย!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.dayName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryStat(label: 'เวลา', value: fmtDuration(s.duration)),
              _SummaryStat(label: 'เซ็ต', value: '${s.completedSets}'),
              _SummaryStat(label: 'น้ำหนักรวม', value: '${fmtNumber(s.volumeLoad)} kg'),
            ],
          ),
          if (result.records.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('สถิติใหม่ (PR) 🎉',
                style: TextStyle(
                    color: scheme.primary, fontWeight: FontWeight.w700)),
            for (final r in result.records)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    '${r.exercise.name}: ${fmtKg(r.weight)} kg × ${r.reps} (1RM ประมาณ ${fmtKg(Progression.roundLoad(r.e1rm))} kg)'),
              ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('เยี่ยม!'),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
