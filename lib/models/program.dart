import '../data/exercise_library.dart';
import 'exercise.dart';
import 'profile.dart';

/// One exercise prescription inside a program day.
class ProgramExercise {
  const ProgramExercise({
    required this.exerciseId,
    required this.sets,
    required this.repMin,
    required this.repMax,
    required this.rir,
    required this.restSec,
    this.superset,
    this.note,
  });

  final String exerciseId;
  final int sets;
  final int repMin;
  final int repMax;

  /// Target reps in reserve, e.g. "1–2".
  final String rir;
  final int restSec;

  /// Exercises sharing the same tag are performed as a superset.
  final String? superset;
  final String? note;

  Exercise get exercise => exerciseById[exerciseId]!;

  String get repLabel {
    final unit = exercise.timed ? ' วิ' : '';
    return repMin == repMax ? '$repMin$unit' : '$repMin–$repMax$unit';
  }

  String get restLabel {
    if (restSec < 60) return '$restSec วิ';
    final m = restSec ~/ 60;
    final s = restSec % 60;
    return s == 0 ? '$m นาที' : '$m:${s.toString().padLeft(2, '0')} นาที';
  }

  ProgramExercise copyWith({
    String? exerciseId,
    int? sets,
    int? repMin,
    int? repMax,
    String? rir,
    int? restSec,
    String? superset,
    bool clearSuperset = false,
    String? note,
  }) {
    return ProgramExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      repMin: repMin ?? this.repMin,
      repMax: repMax ?? this.repMax,
      rir: rir ?? this.rir,
      restSec: restSec ?? this.restSec,
      superset: clearSuperset ? null : (superset ?? this.superset),
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': exerciseId,
        'sets': sets,
        'min': repMin,
        'max': repMax,
        'rir': rir,
        'rest': restSec,
        if (superset != null) 'ss': superset,
        if (note != null) 'note': note,
      };

  factory ProgramExercise.fromJson(Map<String, dynamic> j) => ProgramExercise(
        exerciseId: j['id'] as String,
        sets: (j['sets'] as num).toInt(),
        repMin: (j['min'] as num).toInt(),
        repMax: (j['max'] as num).toInt(),
        rir: j['rir'] as String,
        restSec: (j['rest'] as num).toInt(),
        superset: j['ss'] as String?,
        note: j['note'] as String?,
      );
}

class ProgramDay {
  const ProgramDay({
    required this.id,
    required this.name,
    required this.focus,
    required this.weekday,
    required this.exercises,
  });

  final String id;
  final String name;
  final String focus;

  /// 1 = Monday … 7 = Sunday.
  final int weekday;
  final List<ProgramExercise> exercises;

  int get totalSets => exercises.fold(0, (a, e) => a + e.sets);

  /// Rough session length: warm-up + working sets + rest + transitions.
  int get estimatedMinutes => estimateMinutes(exercises);

  ProgramDay copyWith({List<ProgramExercise>? exercises, int? weekday}) =>
      ProgramDay(
        id: id,
        name: name,
        focus: focus,
        weekday: weekday ?? this.weekday,
        exercises: exercises ?? this.exercises,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'focus': focus,
        'weekday': weekday,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory ProgramDay.fromJson(Map<String, dynamic> j) => ProgramDay(
        id: j['id'] as String,
        name: j['name'] as String,
        focus: j['focus'] as String,
        weekday: (j['weekday'] as num).toInt(),
        exercises: [
          for (final e in j['exercises'] as List)
            ProgramExercise.fromJson(e as Map<String, dynamic>),
        ],
      );
}

/// Seconds of work for one set (used for time estimates).
int workSeconds(ProgramExercise pe) {
  if (pe.exercise.timed) return pe.repMax;
  final avgReps = (pe.repMin + pe.repMax) / 2;
  return (avgReps * 3.5).round().clamp(20, 75); // ~3–4 s per rep
}

/// Estimate session duration in minutes, accounting for supersets
/// (paired exercises share rest periods).
int estimateMinutes(List<ProgramExercise> exercises) {
  var seconds = 6 * 60; // general warm-up
  final seenSupersets = <String>{};
  for (var i = 0; i < exercises.length; i++) {
    final pe = exercises[i];
    if (i == 0) seconds += 3 * 60; // ramp-up sets for the first lift
    seconds += 60; // set-up / transition
    if (pe.superset != null) {
      if (seenSupersets.contains(pe.superset)) continue;
      seenSupersets.add(pe.superset!);
      final group = exercises.where((e) => e.superset == pe.superset).toList();
      final rounds =
          group.map((e) => e.sets).reduce((a, b) => a > b ? a : b);
      final work = group.fold<int>(0, (a, e) => a + workSeconds(e));
      seconds += rounds * (work + pe.restSec + 15);
    } else {
      seconds += pe.sets * (workSeconds(pe) + pe.restSec);
    }
  }
  return (seconds / 60).round();
}

class WorkoutProgram {
  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.gymType,
    required this.days,
    required this.equipment,
    required this.cycleWeeks,
    required this.rationale,
    this.isPreset = false,
    this.level,
    this.goal,
  });

  final String id;
  final String name;
  final String description;
  final GymType gymType;
  final List<ProgramDay> days;

  /// Equipment assumed by this program (used for exercise swaps).
  final Set<Equipment> equipment;

  /// Mesocycle length in weeks; the final week is a deload.
  final int cycleWeeks;

  /// Evidence-based notes explaining the design.
  final List<String> rationale;
  final bool isPreset;
  final TrainingLevel? level;
  final Goal? goal;

  int get daysPerWeek => days.length;

  int get averageMinutes => days.isEmpty
      ? 0
      : (days.fold<int>(0, (a, d) => a + d.estimatedMinutes) / days.length)
          .round();

  ProgramDay? dayForWeekday(int weekday) {
    for (final d in days) {
      if (d.weekday == weekday) return d;
    }
    return null;
  }

  ProgramDay? dayById(String id) {
    for (final d in days) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Weekly volume per muscle using fractional set counting
  /// (direct sets = 1, indirect = 0.5).
  Map<Muscle, double> get weeklyVolume {
    final volume = {for (final m in Muscle.values) m: 0.0};
    for (final day in days) {
      for (final pe in day.exercises) {
        pe.exercise.muscles.forEach((m, f) {
          volume[m] = volume[m]! + pe.sets * f;
        });
      }
    }
    return volume;
  }

  /// How many days per week each muscle receives at least one direct set.
  Map<Muscle, int> get weeklyFrequency {
    final freq = {for (final m in Muscle.values) m: 0};
    for (final day in days) {
      final hit = <Muscle>{};
      for (final pe in day.exercises) {
        pe.exercise.muscles.forEach((m, f) {
          if (f >= 0.5) hit.add(m);
        });
      }
      for (final m in hit) {
        freq[m] = freq[m]! + 1;
      }
    }
    return freq;
  }

  WorkoutProgram copyWith({
    String? id,
    String? name,
    List<ProgramDay>? days,
    bool? isPreset,
  }) {
    return WorkoutProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description,
      gymType: gymType,
      days: days ?? this.days,
      equipment: equipment,
      cycleWeeks: cycleWeeks,
      rationale: rationale,
      isPreset: isPreset ?? this.isPreset,
      level: level,
      goal: goal,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'gymType': gymType.name,
        'days': days.map((d) => d.toJson()).toList(),
        'equipment': equipment.map((e) => e.name).toList(),
        'cycleWeeks': cycleWeeks,
        'rationale': rationale,
        'isPreset': isPreset,
        if (level != null) 'level': level!.name,
        if (goal != null) 'goal': goal!.name,
      };

  factory WorkoutProgram.fromJson(Map<String, dynamic> j) => WorkoutProgram(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        gymType: GymType.values.byName(j['gymType'] as String),
        days: [
          for (final d in j['days'] as List)
            ProgramDay.fromJson(d as Map<String, dynamic>),
        ],
        equipment: {
          for (final e in j['equipment'] as List)
            Equipment.values.byName(e as String),
        },
        cycleWeeks: (j['cycleWeeks'] as num).toInt(),
        rationale: [for (final r in j['rationale'] as List) r as String],
        isPreset: j['isPreset'] as bool? ?? false,
        level: j['level'] == null
            ? null
            : TrainingLevel.values.byName(j['level'] as String),
        goal: j['goal'] == null ? null : Goal.values.byName(j['goal'] as String),
      );
}
