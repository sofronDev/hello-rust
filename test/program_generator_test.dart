import 'dart:convert';

import 'package:fitplan/data/exercise_library.dart';
import 'package:fitplan/data/preset_programs.dart';
import 'package:fitplan/models/exercise.dart';
import 'package:fitplan/models/profile.dart';
import 'package:fitplan/models/program.dart';
import 'package:fitplan/services/program_generator.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = UserProfile(
  name: 'Test',
  sex: Sex.male,
  age: 30,
  weightKg: 75,
  heightCm: 175,
  experience: Experience.sixTo24Months,
  goal: Goal.muscle,
  daysPerWeek: 4,
  sessionMinutes: 60,
  preferredGym: GymType.full,
);

const _majors = [
  Muscle.chest,
  Muscle.back,
  Muscle.shoulders,
  Muscle.quads,
  Muscle.hamstrings,
  Muscle.glutes,
];

/// Every combination of the inputs that change program structure.
Iterable<UserProfile> _allProfiles() sync* {
  for (final experience in Experience.values) {
    for (final goal in Goal.values) {
      for (var days = 2; days <= 6; days++) {
        for (final minutes in const [30, 45, 60, 75, 90]) {
          yield _base.copyWith(
            experience: experience,
            goal: goal,
            daysPerWeek: days,
            sessionMinutes: minutes,
          );
        }
      }
    }
  }
}

void main() {
  const generator = ProgramGenerator();

  group('every generated program', () {
    test('respects equipment, limitations, days and time budget', () {
      final limitationSets = <Set<Limitation>>[
        {},
        {Limitation.knee},
        {Limitation.lowerBack, Limitation.shoulder},
        Limitation.values.toSet(),
      ];
      final homeKits = <Set<Equipment>>[
        {},
        {Equipment.dumbbell, Equipment.bench},
        {Equipment.band, Equipment.pullUpBar},
      ];
      var checked = 0;
      for (final base in _allProfiles()) {
        for (final limits in limitationSets) {
          for (final kit in homeKits) {
            final p = base.copyWith(limitations: limits, homeEquipment: kit);
            final plan = generator.generate(p);
            expect(plan.programs.map((x) => x.gymType).toSet(),
                GymType.values.toSet());
            for (final program in plan.programs) {
              checked++;
              final reason = '${program.name} ${p.toJson()}';
              expect(program.days.length, ProgramGenerator.liftingDays(p),
                  reason: reason);
              final available = equipmentFor(program.gymType, kit);
              final weekdays = <int>{};
              for (final day in program.days) {
                expect(weekdays.add(day.weekday), isTrue, reason: reason);
                expect(day.exercises, isNotEmpty, reason: reason);
                final ids = day.exercises.map((e) => e.exerciseId).toList();
                expect(ids.toSet().length, ids.length,
                    reason: 'duplicate exercise in ${day.name} $reason');
                for (final pe in day.exercises) {
                  final e = pe.exercise;
                  expect(e.availableWith(available), isTrue,
                      reason: '${e.id} needs ${e.equipment} $reason');
                  expect(e.avoidWith.intersection(limits), isEmpty,
                      reason: '${e.id} conflicts with $limits');
                  expect(pe.sets, inInclusiveRange(1, 5));
                  expect(pe.repMin, lessThanOrEqualTo(pe.repMax));
                }
                // Small tolerance: the estimate rounds per exercise.
                expect(day.estimatedMinutes,
                    lessThanOrEqualTo(p.sessionMinutes + 4),
                    reason: '${day.name} too long $reason');
              }
              final cap = ProgramGenerator.weeklyCap(p.level);
              program.weeklyVolume.forEach((m, v) {
                expect(v, lessThanOrEqualTo(cap), reason: '$m $reason');
              });
            }
          }
        }
      }
      expect(checked, greaterThan(5000));
    });

    test('trains every major muscle at least twice a week (ACSM 2026)', () {
      for (final p in _allProfiles()) {
        for (final type in GymType.values) {
          final program = generator.build(p, type, id: 'x');
          final freq = program.weeklyFrequency;
          for (final m in _majors) {
            expect(freq[m], greaterThanOrEqualTo(2),
                reason: '$m in ${program.name} ${p.toJson()}');
          }
        }
      }
    });

    test('trained lifters with ≥60 min reach ~10 weekly sets per muscle', () {
      for (final experience in [
        Experience.sixTo24Months,
        Experience.twoToFiveYears,
        Experience.overFiveYears,
      ]) {
        for (var days = 3; days <= 6; days++) {
          final p = _base.copyWith(
              experience: experience, daysPerWeek: days, sessionMinutes: 60);
          for (final type in [GymType.full, GymType.mid]) {
            final v = generator.build(p, type, id: 'x').weeklyVolume;
            for (final m in [
              Muscle.chest,
              Muscle.back,
              Muscle.quads,
              Muscle.hamstrings,
              Muscle.glutes,
            ]) {
              expect(v[m], greaterThanOrEqualTo(9),
                  reason: '$m ${type.name} $days d $experience');
            }
          }
        }
      }
    });
  });

  test('beginners are capped at 4 lifting days', () {
    final p = _base.copyWith(experience: Experience.none, daysPerWeek: 6);
    expect(ProgramGenerator.liftingDays(p), 4);
    final program = generator.build(p, GymType.full, id: 'x');
    expect(program.days.length, 4);
    expect(program.rationale.any((r) => r.contains('คาร์ดิโอ')), isTrue);
  });

  test('split matches days per week', () {
    String splitOf(int days) => generator
        .build(_base.copyWith(daysPerWeek: days), GymType.full, id: 'x')
        .days
        .map((d) => d.name)
        .join(',');
    expect(splitOf(2), 'Full Body A,Full Body B');
    expect(splitOf(3), 'Full Body A,Full Body B,Full Body C');
    expect(splitOf(4), 'Upper A,Lower A,Upper B,Lower B');
    expect(splitOf(5), 'Upper A,Lower A,Push,Pull,Legs');
    expect(splitOf(6), 'Push A,Pull A,Legs A,Push B,Pull B,Legs B');
  });

  test('strength goal uses heavy (≤6 rep) main lifts and long rests', () {
    final p = _base.copyWith(
        experience: Experience.twoToFiveYears, goal: Goal.strength);
    final program = generator.build(p, GymType.full, id: 'x');
    final first = program.days.first.exercises.first;
    expect(first.repMax, lessThanOrEqualTo(6));
    expect(first.restSec, 180);
    expect(first.exercise.strengthLift, isTrue);
  });

  test('home gym without equipment uses bodyweight only', () {
    final p = _base.copyWith(homeEquipment: {});
    final program = generator.build(p, GymType.home, id: 'x');
    for (final day in program.days) {
      for (final pe in day.exercises) {
        expect(pe.exercise.equipment, {Equipment.bodyweight},
            reason: pe.exerciseId);
      }
    }
  });

  test('full and home variants differ in equipment', () {
    final plan = generator.generate(_base);
    final full = plan.byType(GymType.full);
    final home = plan.byType(GymType.home);
    bool usesMachine(WorkoutProgram p) => p.days.any((d) => d.exercises
        .any((e) => e.exercise.equipment.contains(Equipment.machine)));
    expect(usesMachine(full), isTrue);
    expect(usesMachine(home), isFalse);
    expect(plan.recommended, GymType.full);
  });

  test('short sessions use supersets', () {
    final p = _base.copyWith(sessionMinutes: 30);
    final program = generator.build(p, GymType.full, id: 'x');
    expect(
        program.days.any((d) => d.exercises.any((e) => e.superset != null)),
        isTrue);
  });

  test('older adults get power-focused cues on main lifts', () {
    final p = _base.copyWith(age: 67);
    final program = generator.build(p, GymType.full, id: 'x');
    expect(program.days.first.exercises.first.note, contains('เร็ว'));
  });

  test('program JSON round-trips', () {
    final program = generator.build(_base, GymType.mid, id: 'abc');
    final copy = WorkoutProgram.fromJson(
        jsonDecode(jsonEncode(program.toJson())) as Map<String, dynamic>);
    expect(jsonEncode(copy.toJson()), jsonEncode(program.toJson()));
  });

  test('presets build with unique ids', () {
    expect(presetPrograms.length, presetSpecs.length);
    expect(presetPrograms.map((p) => p.id).toSet().length,
        presetPrograms.length);
    for (final p in presetPrograms) {
      expect(p.isPreset, isTrue);
      expect(p.days, isNotEmpty);
    }
  });

  test('exercise library ids are unique and muscles valid', () {
    final ids = exerciseLibrary.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final e in exerciseLibrary) {
      expect(e.muscles.values.every((v) => v == 1 || v == 0.5), isTrue,
          reason: e.id);
      expect(e.muscles.values.contains(1), isTrue, reason: e.id);
    }
  });
}
