import '../data/exercise_library.dart';
import 'exercise.dart';

class SetLog {
  SetLog({this.weight, this.reps, this.done = false});

  double? weight;
  int? reps;
  bool done;

  Map<String, dynamic> toJson() => {
        if (weight != null) 'w': weight,
        if (reps != null) 'r': reps,
        if (done) 'd': true,
      };

  factory SetLog.fromJson(Map<String, dynamic> j) => SetLog(
        weight: (j['w'] as num?)?.toDouble(),
        reps: (j['r'] as num?)?.toInt(),
        done: j['d'] as bool? ?? false,
      );
}

class ExerciseLog {
  ExerciseLog({
    required this.exerciseId,
    required this.repMin,
    required this.repMax,
    required this.rir,
    required this.restSec,
    required this.sets,
    this.superset,
  });

  String exerciseId;
  int repMin;
  int repMax;
  String rir;
  int restSec;
  String? superset;
  List<SetLog> sets;

  Exercise get exercise => exerciseById[exerciseId]!;

  Iterable<SetLog> get completedSets =>
      sets.where((s) => s.done && (s.reps ?? 0) > 0);

  /// Total load lifted (kg × reps) for completed sets.
  double get volumeLoad => completedSets.fold(
      0, (a, s) => a + (s.weight ?? 0) * (s.reps ?? 0));

  Map<String, dynamic> toJson() => {
        'id': exerciseId,
        'min': repMin,
        'max': repMax,
        'rir': rir,
        'rest': restSec,
        if (superset != null) 'ss': superset,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> j) => ExerciseLog(
        exerciseId: j['id'] as String,
        repMin: (j['min'] as num).toInt(),
        repMax: (j['max'] as num).toInt(),
        rir: j['rir'] as String? ?? '1–2',
        restSec: (j['rest'] as num?)?.toInt() ?? 90,
        superset: j['ss'] as String?,
        sets: [
          for (final s in j['sets'] as List)
            SetLog.fromJson(s as Map<String, dynamic>),
        ],
      );
}

class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.programId,
    required this.programName,
    required this.dayId,
    required this.dayName,
    required this.startedAt,
    required this.exercises,
    this.finishedAt,
    this.deload = false,
    this.note = '',
  });

  final String id;
  final String programId;
  final String programName;
  final String dayId;
  final String dayName;
  final DateTime startedAt;
  DateTime? finishedAt;
  final bool deload;
  String note;
  List<ExerciseLog> exercises;

  int get completedSets =>
      exercises.fold(0, (a, e) => a + e.completedSets.length);

  int get plannedSets => exercises.fold(0, (a, e) => a + e.sets.length);

  double get volumeLoad => exercises.fold(0, (a, e) => a + e.volumeLoad);

  Duration get duration =>
      (finishedAt ?? DateTime.now()).difference(startedAt);

  /// Completed sets per muscle (fractional counting).
  Map<Muscle, double> get muscleSets {
    final out = <Muscle, double>{};
    for (final e in exercises) {
      final n = e.completedSets.length;
      if (n == 0) continue;
      e.exercise.muscles.forEach((m, f) {
        out[m] = (out[m] ?? 0) + n * f;
      });
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'programId': programId,
        'programName': programName,
        'dayId': dayId,
        'dayName': dayName,
        'startedAt': startedAt.toIso8601String(),
        if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
        if (deload) 'deload': true,
        if (note.isNotEmpty) 'note': note,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
        id: j['id'] as String,
        programId: j['programId'] as String,
        programName: j['programName'] as String,
        dayId: j['dayId'] as String,
        dayName: j['dayName'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        finishedAt: j['finishedAt'] == null
            ? null
            : DateTime.parse(j['finishedAt'] as String),
        deload: j['deload'] as bool? ?? false,
        note: j['note'] as String? ?? '',
        exercises: [
          for (final e in j['exercises'] as List)
            ExerciseLog.fromJson(e as Map<String, dynamic>),
        ],
      );
}

class BodyWeightEntry {
  const BodyWeightEntry({required this.date, required this.kg});

  final DateTime date;
  final double kg;

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'kg': kg};

  factory BodyWeightEntry.fromJson(Map<String, dynamic> j) => BodyWeightEntry(
        date: DateTime.parse(j['date'] as String),
        kg: (j['kg'] as num).toDouble(),
      );
}
