import '../models/exercise.dart';
import '../models/profile.dart';
import '../models/workout_log.dart';

class Suggestion {
  const Suggestion({this.weight, required this.text, this.last});

  /// Suggested working weight (kg) or null when not applicable.
  final double? weight;
  final String text;
  final ExerciseLog? last;
}

class PersonalRecord {
  const PersonalRecord(this.exercise, this.e1rm, this.weight, this.reps);

  final Exercise exercise;
  final double e1rm;
  final double weight;
  final int reps;
}

/// Double progression: add reps until every set reaches the top of the rep
/// range, then add load (Plotkin et al. 2022 show load and rep progression
/// produce similar hypertrophy).
class Progression {
  const Progression._();

  static bool tracksWeight(Exercise e) =>
      e.loadable && !e.equipment.contains(Equipment.band);

  /// Most recent finished log for [exerciseId] with at least one completed set.
  static ExerciseLog? lastLog(
      Iterable<WorkoutSession> sessions, String exerciseId) {
    WorkoutSession? best;
    ExerciseLog? log;
    for (final s in sessions) {
      if (s.finishedAt == null) continue;
      for (final e in s.exercises) {
        if (e.exerciseId != exerciseId || e.completedSets.isEmpty) continue;
        if (best == null || s.startedAt.isAfter(best.startedAt)) {
          best = s;
          log = e;
        }
      }
    }
    return log;
  }

  static double increment(Exercise e, double current) {
    if (e.equipment.contains(Equipment.dumbbell) &&
        !e.equipment.contains(Equipment.barbell)) {
      return current < 10 ? 1 : 2;
    }
    return e.pattern.isLowerBody ? 5 : 2.5;
  }

  static double roundLoad(double kg) => (kg * 2).round() / 2;

  static Suggestion suggest(
    Exercise e,
    ExerciseLog? last, {
    required int repMin,
    required int repMax,
    required String rir,
    required int plannedSets,
  }) {
    if (last == null || last.completedSets.isEmpty) {
      return Suggestion(
        text: tracksWeight(e)
            ? 'ครั้งแรก: เลือกน้ำหนักที่ทำได้ $repMin–$repMax ครั้ง โดยยังเหลือแรงอีก $rir ครั้ง'
            : 'ครั้งแรก: ทำให้ได้ $repMin–$repMax ครั้ง โดยยังเหลือแรงอีก $rir ครั้ง',
      );
    }
    final done = last.completedSets.toList();
    final repsText = done.map((s) => s.reps).join('/');

    if (!tracksWeight(e)) {
      final allTop = done.length >= plannedSets &&
          done.every((s) => (s.reps ?? 0) >= repMax);
      final harder = e.equipment.contains(Equipment.band)
          ? 'ใช้ยางที่แข็งขึ้นหรือยืนห่างขึ้น'
          : 'ใช้ท่าที่ยากขึ้น ทำช้าลง หรือค้างจังหวะ';
      return Suggestion(
        last: last,
        text: allTop
            ? 'ครั้งก่อน $repsText ครั้ง ครบเป้าแล้ว — $harder'
            : 'ครั้งก่อน $repsText ครั้ง — พยายามเพิ่มอีก 1–2 ครั้ง/เซ็ต',
      );
    }

    // A blank weight means "same as the set above".
    final sets = <(double, int)>[];
    double? carry;
    for (final s in done) {
      carry = s.weight ?? carry;
      sets.add((carry ?? 0, s.reps ?? 0));
    }
    final top = sets.fold<double>(0, (a, s) => s.$1 > a ? s.$1 : a);
    if (top <= 0) {
      return Suggestion(
        last: last,
        text: 'ครั้งก่อน $repsText ครั้ง — ลองบันทึกน้ำหนักเพื่อให้แอปแนะนำได้',
      );
    }
    final atTop = sets.where((s) => s.$1 == top).toList();
    final lastText = 'ครั้งก่อน ${fmtKg(top)} kg × $repsText';

    // Add load only when every planned set reached the top of the range.
    if (atTop.length >= plannedSets && atTop.every((s) => s.$2 >= repMax)) {
      final next = roundLoad(top + increment(e, top));
      return Suggestion(
        weight: next,
        last: last,
        text: '$lastText ครบเป้าทุกเซ็ต → เพิ่มเป็น ${fmtKg(next)} kg',
      );
    }
    if (atTop.first.$2 < repMin - 2) {
      final next = roundLoad(top * 0.92);
      return Suggestion(
        weight: next,
        last: last,
        text: '$lastText ต่ำกว่าเป้า → ลดเหลือ ${fmtKg(next)} kg แล้วค่อยไต่ขึ้น',
      );
    }
    return Suggestion(
      weight: top,
      last: last,
      text: '$lastText → ใช้น้ำหนักเดิม เพิ่มครั้งให้ถึง $repMax ทุกเซ็ต',
    );
  }

  /// Estimated 1RM (Epley). Only meaningful for ≤15 reps.
  static double? e1rm(double? weight, int? reps) {
    if (weight == null || reps == null || weight <= 0 || reps <= 0) {
      return null;
    }
    if (reps == 1) return weight;
    return weight * (1 + reps.clamp(1, 15) / 30);
  }

  static double? bestE1rm(ExerciseLog log) {
    double? best;
    for (final s in log.completedSets) {
      final v = e1rm(s.weight, s.reps);
      if (v != null && (best == null || v > best)) best = v;
    }
    return best;
  }

  /// PRs set in [session] compared with all earlier finished sessions.
  static List<PersonalRecord> personalRecords(
      WorkoutSession session, Iterable<WorkoutSession> history) {
    final prs = <PersonalRecord>[];
    for (final log in session.exercises) {
      if (!tracksWeight(log.exercise)) continue;
      SetLog? bestSet;
      double best = 0;
      for (final s in log.completedSets) {
        final v = e1rm(s.weight, s.reps) ?? 0;
        if (v > best) {
          best = v;
          bestSet = s;
        }
      }
      if (bestSet == null) continue;
      double previous = 0;
      for (final h in history) {
        if (h.id == session.id || h.finishedAt == null) continue;
        if (!h.startedAt.isBefore(session.startedAt)) continue;
        for (final e in h.exercises) {
          if (e.exerciseId != log.exerciseId) continue;
          final v = bestE1rm(e) ?? 0;
          if (v > previous) previous = v;
        }
      }
      // A first-ever log is not a PR.
      if (previous > 0 && best > previous) {
        prs.add(PersonalRecord(
            log.exercise, best, bestSet.weight!, bestSet.reps!));
      }
    }
    return prs;
  }
}

String fmtKg(double kg) =>
    kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
